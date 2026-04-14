import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  FirestoreEvent,
  Change,
  onDocumentUpdated,
  QueryDocumentSnapshot,
} from "firebase-functions/v2/firestore";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const mailCollection = "mail";
const DEFAULT_SUPERVISOR_MAX_STUDENTS = 15;

interface QueuedEmail {
  to: string | string[];
  subject: string;
  html: string;
  text?: string;
}

interface UserRecord {
  email?: string;
  displayName?: string;
  role?: string;
  [key: string]: unknown;
}

interface StudentRecord {
  fullName?: string;
  registrationNumber?: string;
  program?: string;
  currentSupervisorId?: string | null;
  [key: string]: unknown;
}

interface SupervisorProfileRecord {
  fullName?: string;
  department?: string;
  [key: string]: unknown;
}

interface PlacementRecord {
  studentId?: string;
  companyId?: string;
  universitySupervisorId?: string;
  status?: string;
  supervisorFeedback?: string;
  [key: string]: unknown;
}

interface CompanyRecord {
  name?: string;
  location?: string;
  city?: string;
  [key: string]: unknown;
}

interface AssignRequest {
  reAssignAll?: boolean;
}

interface ManualAssignRequest {
  studentId?: string;
  supervisorId?: string;
}

interface AssignmentStudent {
  id: string;
  fullName: string;
  program: string;
  gender: string | null;
}

interface SupervisorDistribution {
  programCounts: Map<string, number>;
  genderCounts: Map<string, number>;
}

interface SupervisorAssignmentState {
  id: string;
  fullName: string;
  currentLoad: number;
  maxStudents: number;
  specialties: string[];
  department: string;
  isAvailable: boolean;
}

function formatRole(role?: string): string {
  if (!role) return "account";
  return role
    .replace(/([a-z])([A-Z])/g, "$1 $2")
    .replace(/_/g, " ")
    .replace(/\b\w/g, (match) => match.toUpperCase());
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function buildEmailShell(title: string, intro: string, body: string): string {
  return `
    <div style="background:#f6f8f3;padding:24px;font-family:Arial,sans-serif;color:#17351c;">
      <div style="max-width:640px;margin:0 auto;background:#ffffff;border-radius:18px;overflow:hidden;border:1px solid #e3eadf;">
        <div style="background:linear-gradient(135deg,#1B5E20,#2E7D32);padding:24px 28px;color:#ffffff;">
          <div style="font-size:12px;letter-spacing:1.2px;font-weight:700;opacity:0.9;">MUST DIMS</div>
          <div style="font-size:24px;font-weight:700;margin-top:8px;">${escapeHtml(title)}</div>
        </div>
        <div style="padding:28px;">
          <p style="margin:0 0 16px;font-size:15px;line-height:1.6;">${intro}</p>
          <div style="font-size:14px;line-height:1.7;color:#34503a;">${body}</div>
          <p style="margin:24px 0 0;font-size:13px;color:#5f7263;">
            Mbarara University of Science and Technology Internship Management System
          </p>
        </div>
      </div>
    </div>
  `;
}

function normalizeText(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeComparable(value: unknown): string {
  return normalizeText(value).toLowerCase().replace(/[^a-z0-9]+/g, "");
}

function normalizeGender(value: unknown): string | null {
  const normalized = normalizeComparable(value);

  if (!normalized) {
    return null;
  }

  if (normalized === "m" || normalized === "male") {
    return "male";
  }

  if (normalized === "f" || normalized === "female") {
    return "female";
  }

  return normalized;
}

function readStudentGender(data: admin.firestore.DocumentData): string | null {
  return normalizeGender(
    data.gender ??
      data.sex ??
      data.studentGender ??
      data.userGender,
  );
}

function matchesComparable(left: string, right: string): boolean {
  if (!left || !right) {
    return false;
  }

  return left === right || left.includes(right) || right.includes(left);
}

function supervisorMatchesProgram(
  supervisor: SupervisorAssignmentState,
  studentProgram: string,
): boolean {
  const normalizedProgram = normalizeComparable(studentProgram);

  if (!normalizedProgram) {
    return false;
  }

  const matchesSpecialty = supervisor.specialties.some((specialty) =>
    matchesComparable(normalizeComparable(specialty), normalizedProgram),
  );

  return (
    matchesSpecialty ||
    matchesComparable(normalizeComparable(supervisor.department), normalizedProgram)
  );
}

function createEmptyDistribution(): SupervisorDistribution {
  return {
    programCounts: new Map<string, number>(),
    genderCounts: new Map<string, number>(),
  };
}

function getSupervisorDistribution(
  distributions: Map<string, SupervisorDistribution>,
  supervisorId: string,
): SupervisorDistribution {
  const existing = distributions.get(supervisorId);

  if (existing) {
    return existing;
  }

  const distribution = createEmptyDistribution();
  distributions.set(supervisorId, distribution);
  return distribution;
}

function incrementCounter(counter: Map<string, number>, key: string | null): void {
  if (!key) {
    return;
  }

  counter.set(key, (counter.get(key) ?? 0) + 1);
}

async function queueEmail(payload: QueuedEmail): Promise<void> {
  await db.collection(mailCollection).add({
    to: payload.to,
    message: {
      subject: payload.subject,
      text: payload.text,
      html: payload.html,
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function getDocument<T>(collection: string, id?: string | null): Promise<T | null> {
  if (!id) return null;
  const snapshot = await db.collection(collection).doc(id).get();
  if (!snapshot.exists) return null;
  return snapshot.data() as T;
}

async function assertAdminUser(callerUid: string): Promise<void> {
  const callerDoc = await db.collection("users").doc(callerUid).get();

  if (!callerDoc.exists || callerDoc.data()?.role !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only admins can run supervisor assignment",
    );
  }
}

async function buildSupervisorDistributions(
  firestore: admin.firestore.Firestore,
): Promise<Map<string, SupervisorDistribution>> {
  const studentsSnap = await firestore.collection("students").get();
  const distributions = new Map<string, SupervisorDistribution>();

  for (const studentDoc of studentsSnap.docs) {
    const data = studentDoc.data();
    const supervisorId = normalizeText(data.currentSupervisorId);

    if (!supervisorId) {
      continue;
    }

    const distribution = getSupervisorDistribution(distributions, supervisorId);

    incrementCounter(
      distribution.programCounts,
      normalizeComparable(data.program),
    );
    incrementCounter(distribution.genderCounts, readStudentGender(data));
  }

  return distributions;
}

function buildAssignmentStudents(
  studentDocs: QueryDocumentSnapshot[],
): AssignmentStudent[] {
  return studentDocs.map((doc) => {
    const data = doc.data();

    return {
      id: doc.id,
      fullName: normalizeText(data.fullName) || "Unknown Student",
      program: normalizeText(data.program) || "Unknown",
      gender: readStudentGender(data),
    };
  });
}

function buildSupervisorStates(
  supervisorsSnap: admin.firestore.QuerySnapshot,
): SupervisorAssignmentState[] {
  return supervisorsSnap.docs.map((doc) => {
    const data = doc.data();

    return {
      id: doc.id,
      fullName: normalizeText(data.fullName) || "Unnamed Supervisor",
      currentLoad: Number(data.currentLoad ?? 0),
      maxStudents: Number(data.maxStudents ?? DEFAULT_SUPERVISOR_MAX_STUDENTS),
      specialties: Array.isArray(data.programSpecialties)
        ? (data.programSpecialties as unknown[])
            .map((value) => normalizeText(value))
            .filter((value) => value.length > 0)
        : [],
      department: normalizeText(data.department),
      isAvailable: data.isAvailable ?? true,
    };
  });
}

function countProgramMatches(
  student: AssignmentStudent,
  supervisors: SupervisorAssignmentState[],
): number {
  return supervisors.filter((supervisor) =>
    supervisor.isAvailable &&
    supervisor.currentLoad < supervisor.maxStudents &&
    supervisorMatchesProgram(supervisor, student.program),
  ).length;
}

function calculateProgramBalanceScore(
  supervisor: SupervisorAssignmentState,
  studentProgram: string,
  distributions: Map<string, SupervisorDistribution>,
): number {
  const normalizedProgram = normalizeComparable(studentProgram);

  if (!normalizedProgram) {
    return 0;
  }

  const distribution = getSupervisorDistribution(distributions, supervisor.id);
  const sameProgramCount = distribution.programCounts.get(normalizedProgram) ?? 0;

  return sameProgramCount === 0 ? 18 : Math.max(0, 18 - sameProgramCount * 6);
}

function calculateGenderBalanceScore(
  supervisor: SupervisorAssignmentState,
  studentGender: string | null,
  distributions: Map<string, SupervisorDistribution>,
): number {
  if (studentGender !== "male" && studentGender !== "female") {
    return 0;
  }

  const distribution = getSupervisorDistribution(distributions, supervisor.id);
  const maleCount = distribution.genderCounts.get("male") ?? 0;
  const femaleCount = distribution.genderCounts.get("female") ?? 0;

  const beforeGap = Math.abs(maleCount - femaleCount);
  const afterMaleCount = maleCount + (studentGender === "male" ? 1 : 0);
  const afterFemaleCount = femaleCount + (studentGender === "female" ? 1 : 0);
  const afterGap = Math.abs(afterMaleCount - afterFemaleCount);

  return (beforeGap - afterGap) * 8;
}

function calculateSupervisorScore(
  supervisor: SupervisorAssignmentState,
  student: AssignmentStudent,
  distributions: Map<string, SupervisorDistribution>,
): number {
  const loadRatio = supervisor.maxStudents > 0
    ? supervisor.currentLoad / supervisor.maxStudents
    : 1;

  let score = 120 - loadRatio * 45 - supervisor.currentLoad * 2;

  if (supervisorMatchesProgram(supervisor, student.program)) {
    score += 42;
  }

  score += calculateProgramBalanceScore(
    supervisor,
    student.program,
    distributions,
  );
  score += calculateGenderBalanceScore(
    supervisor,
    student.gender,
    distributions,
  );

  const remainingSlotsAfterAssignment =
    supervisor.maxStudents - supervisor.currentLoad - 1;
  score += Math.min(Math.max(remainingSlotsAfterAssignment, 0), 6);

  return score;
}

function updateDistributionAfterAssignment(
  distributions: Map<string, SupervisorDistribution>,
  supervisorId: string,
  student: AssignmentStudent,
): void {
  const distribution = getSupervisorDistribution(distributions, supervisorId);

  incrementCounter(
    distribution.programCounts,
    normalizeComparable(student.program),
  );
  incrementCounter(distribution.genderCounts, student.gender);
}

export const sendAccountApprovedEmail = onDocumentUpdated(
  "users/{userId}",
  async (event: FirestoreEvent<Change<QueryDocumentSnapshot> | undefined>) => {
    const beforeSnapshot = event.data?.before;
    const afterSnapshot = event.data?.after;

    if (!beforeSnapshot || !afterSnapshot) {
      return;
    }

    const before = beforeSnapshot.data() as UserRecord;
    const after = afterSnapshot.data() as UserRecord;

    if (before.isApproved === true || after.isApproved !== true) {
      return;
    }

    if (!after.email) {
      console.warn("[EMAIL] Skipping approval email because user has no email", afterSnapshot.id);
      return;
    }

    const recipientName = (after.displayName || "Student").trim();
    const roleLabel = formatRole(after.role);

    await queueEmail({
      to: after.email,
      subject: "Your MUST DIMS account has been approved",
      text: `Hello ${recipientName}, your ${roleLabel} account has been approved. You can now sign in and continue using MUST DIMS.`,
      html: buildEmailShell(
        "Account Approved",
        `Hello ${escapeHtml(recipientName)},`,
        `
          <p>Your ${escapeHtml(roleLabel)} account has been approved and is now active.</p>
          <p>You can sign in to MUST DIMS and continue with the next steps in your internship journey.</p>
        `,
      ),
    });

    console.log(`[EMAIL] Queued account approval email for ${afterSnapshot.id}`);
  },
);

export const sendSupervisorAssignedEmail = onDocumentUpdated(
  "students/{studentId}",
  async (event: FirestoreEvent<Change<QueryDocumentSnapshot> | undefined>) => {
    const beforeSnapshot = event.data?.before;
    const afterSnapshot = event.data?.after;

    if (!beforeSnapshot || !afterSnapshot) {
      return;
    }

    const before = beforeSnapshot.data() as StudentRecord;
    const after = afterSnapshot.data() as StudentRecord;

    const previousSupervisorId = before.currentSupervisorId ?? null;
    const currentSupervisorId = after.currentSupervisorId ?? null;

    if (!currentSupervisorId || previousSupervisorId === currentSupervisorId) {
      return;
    }

    const [user, supervisor] = await Promise.all([
      getDocument<UserRecord>("users", afterSnapshot.id),
      getDocument<SupervisorProfileRecord>("supervisorProfiles", currentSupervisorId),
    ]);

    if (!user?.email || !supervisor) {
      console.warn("[EMAIL] Skipping supervisor assignment email due to missing user or supervisor data", afterSnapshot.id);
      return;
    }

    const studentName =
      (after.fullName || user.displayName || "Student").trim();
    const supervisorName = (supervisor.fullName || "your university supervisor").trim();
    const programLine = after.program ? `<p>Programme: ${escapeHtml(String(after.program))}</p>` : "";
    const regNoLine = after.registrationNumber
      ? `<p>Registration Number: ${escapeHtml(String(after.registrationNumber))}</p>`
      : "";

    await queueEmail({
      to: user.email,
      subject: "A university supervisor has been assigned to you",
      text: `Hello ${studentName}, ${supervisorName} has been assigned as your university supervisor on MUST DIMS.`,
      html: buildEmailShell(
        "Supervisor Assigned",
        `Hello ${escapeHtml(studentName)},`,
        `
          <p>${escapeHtml(supervisorName)} has been assigned as your university supervisor.</p>
          ${regNoLine}
          ${programLine}
          <p>You can now continue with the placement process in MUST DIMS.</p>
        `,
      ),
    });

    console.log(`[EMAIL] Queued supervisor assignment email for ${afterSnapshot.id}`);
    return;
  },
);

export const sendPlacementDecisionEmail = onDocumentUpdated(
  "placements/{placementId}",
  async (event: FirestoreEvent<Change<QueryDocumentSnapshot> | undefined>) => {
    const beforeSnapshot = event.data?.before;
    const afterSnapshot = event.data?.after;

    if (!beforeSnapshot || !afterSnapshot) {
      return;
    }

    const before = beforeSnapshot.data() as PlacementRecord;
    const after = afterSnapshot.data() as PlacementRecord;

    const previousStatus = before.status;
    const currentStatus = after.status;

    if (previousStatus === currentStatus) {
      return;
    }

    if (currentStatus !== "approved" && currentStatus !== "rejected") {
      return;
    }

    const studentId = after.studentId;
    if (!studentId) {
      console.warn("[EMAIL] Placement decision missing studentId", afterSnapshot.id);
      return;
    }

    const [user, student, supervisor, company] = await Promise.all([
      getDocument<UserRecord>("users", studentId),
      getDocument<StudentRecord>("students", studentId),
      getDocument<SupervisorProfileRecord>("supervisorProfiles", after.universitySupervisorId),
      getDocument<CompanyRecord>("companies", after.companyId),
    ]);

    if (!user?.email) {
      console.warn("[EMAIL] Skipping placement decision email because student email is missing", studentId);
      return;
    }

    const studentName = (student?.fullName || user.displayName || "Student").trim();
    const supervisorName = (supervisor?.fullName || "your university supervisor").trim();
    const companyName = (company?.name || "your selected company").trim();
    const feedbackBlock =
      currentStatus === "rejected" && after.supervisorFeedback
        ? `<p><strong>Supervisor feedback:</strong><br>${escapeHtml(String(after.supervisorFeedback))}</p>`
        : "";

    const title = currentStatus === "approved" ? "Placement Approved" : "Placement Update";
    const subject =
      currentStatus === "approved"
        ? "Your acceptance letter has been approved"
        : "Your acceptance letter requires revision";
    const intro = `Hello ${escapeHtml(studentName)},`;
    const body =
      currentStatus === "approved"
        ? `
          <p>Your acceptance letter for <strong>${escapeHtml(companyName)}</strong> has been approved by ${escapeHtml(supervisorName)}.</p>
          <p>You can now proceed with your internship activities in MUST DIMS.</p>
        `
        : `
          <p>Your acceptance letter for <strong>${escapeHtml(companyName)}</strong> was reviewed by ${escapeHtml(supervisorName)} and requires revision before approval.</p>
          ${feedbackBlock}
          <p>Please update and resubmit your acceptance letter in MUST DIMS.</p>
        `;

    await queueEmail({
      to: user.email,
      subject,
      text:
        currentStatus === "approved"
          ? `Hello ${studentName}, your acceptance letter for ${companyName} has been approved.`
          : `Hello ${studentName}, your acceptance letter for ${companyName} requires revision. ${after.supervisorFeedback ?? ""}`.trim(),
      html: buildEmailShell(title, intro, body),
    });

    console.log(`[EMAIL] Queued placement ${currentStatus} email for student ${studentId}`);
    return;
  },
);

export const assignSupervisors = functions.https.onCall(
  async (request: functions.https.CallableRequest<AssignRequest>) => {
    const { data, auth } = request;

    if (!auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in as admin",
      );
    }

    const callerUid = auth.uid;

    try {
      await assertAdminUser(callerUid);

      console.log(`[ASSIGN] Admin ${callerUid} started assignment at ${new Date().toISOString()}`);

      const { reAssignAll = false } = data || {};

      if (reAssignAll) {
        console.warn("[ASSIGN] Re-assign ALL mode enabled - resetting all assignments");
        const [allStudentsSnap, supervisorsSnap] = await Promise.all([
          db.collection("students").get(),
          db.collection("supervisorProfiles").get(),
        ]);
        const batch = db.batch();

        allStudentsSnap.docs.forEach((doc) => {
          batch.update(doc.ref, {
            currentSupervisorId: null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        supervisorsSnap.docs.forEach((doc) => {
          batch.update(doc.ref, {
            currentLoad: 0,
            assignedStudentIds: [],
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        await batch.commit();
        console.log(`[ASSIGN] Reset ${allStudentsSnap.size} students and ${supervisorsSnap.size} supervisors`);
      }

      const allStudentsSnap = await db.collection("students").get();
      const unassignedStudents = allStudentsSnap.docs.filter((doc) => {
        const supervisorId = normalizeText(doc.data().currentSupervisorId);
        return supervisorId.length === 0;
      });

      console.log(`[ASSIGN] Found ${unassignedStudents.length} unassigned students`);

      if (unassignedStudents.length === 0) {
        return {
          success: true,
          assignedCount: 0,
          message: "No unassigned students found",
        };
      }

      return await processAssignments(
        buildAssignmentStudents(unassignedStudents),
        callerUid,
        db,
      );
    } catch (error: any) {
      console.error("[ASSIGN] Fatal error:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Assignment failed: ${error.message}`,
      );
    }
  },
);

export const manualAssignSupervisor = functions.https.onCall(
  async (request: functions.https.CallableRequest<ManualAssignRequest>) => {
    const { auth, data } = request;

    if (!auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in as admin",
      );
    }

    await assertAdminUser(auth.uid);

    const studentId = normalizeText(data?.studentId);
    const supervisorId = normalizeText(data?.supervisorId);

    if (!studentId || !supervisorId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "studentId and supervisorId are required",
      );
    }

    const [studentDoc, supervisorDoc] = await Promise.all([
      db.collection("students").doc(studentId).get(),
      db.collection("supervisorProfiles").doc(supervisorId).get(),
    ]);

    if (!studentDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Student not found");
    }

    if (!supervisorDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Supervisor not found");
    }

    const studentData = studentDoc.data() ?? {};
    const supervisorData = supervisorDoc.data() ?? {};

    const previousSupervisorId = normalizeText(studentData.currentSupervisorId);
    const studentName = normalizeText(studentData.fullName) || "Student";
    const supervisorName = normalizeText(supervisorData.fullName) || "Supervisor";
    const maxStudents = Number(
      supervisorData.maxStudents ?? DEFAULT_SUPERVISOR_MAX_STUDENTS,
    );
    const currentLoad = Number(supervisorData.currentLoad ?? 0);
    const isAvailable = supervisorData.isAvailable ?? true;

    if (!isAvailable) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Selected supervisor is not available",
      );
    }

    if (previousSupervisorId === supervisorId) {
      return {
        success: true,
        message: `${studentName} is already assigned to ${supervisorName}`,
      };
    }

    if (currentLoad >= maxStudents) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `${supervisorName} has reached the maximum allocation limit of ${maxStudents}`,
      );
    }

    const batch = db.batch();

    batch.update(studentDoc.ref, {
      currentSupervisorId: supervisorId,
      assignedAt: admin.firestore.FieldValue.serverTimestamp(),
      assignedBy: auth.uid,
      assignmentMethod: "manual",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    batch.update(supervisorDoc.ref, {
      currentLoad: admin.firestore.FieldValue.increment(1),
      assignedStudentIds: admin.firestore.FieldValue.arrayUnion(studentId),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (previousSupervisorId) {
      const previousSupervisorDoc = await db
        .collection("supervisorProfiles")
        .doc(previousSupervisorId)
        .get();

      if (previousSupervisorDoc.exists) {
        batch.update(previousSupervisorDoc.ref, {
          currentLoad: admin.firestore.FieldValue.increment(-1),
          assignedStudentIds: admin.firestore.FieldValue.arrayRemove(studentId),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();

    return {
      success: true,
      message: previousSupervisorId
        ? `Reassigned ${studentName} to ${supervisorName}`
        : `Assigned ${studentName} to ${supervisorName}`,
    };
  },
);

async function processAssignments(
  students: AssignmentStudent[],
  callerUid: string,
  firestore: admin.firestore.Firestore,
) {
  console.log(`[ASSIGN] Processing ${students.length} students for assignment`);

  const supervisorsSnap = await firestore.collection("supervisorProfiles").get();
  console.log(`[ASSIGN] Fetched ${supervisorsSnap.size} total supervisors`);

  let supervisors = buildSupervisorStates(supervisorsSnap);
  const distributions = await buildSupervisorDistributions(firestore);

  console.log("[ASSIGN] All supervisors:", supervisors.map((supervisor) => ({
    id: supervisor.id,
    name: supervisor.fullName,
    load: supervisor.currentLoad,
    max: supervisor.maxStudents,
    available: supervisor.isAvailable,
  })));

  supervisors = supervisors.filter((supervisor) =>
    supervisor.isAvailable && supervisor.currentLoad < supervisor.maxStudents,
  );

  console.log(`[ASSIGN] Found ${supervisors.length} supervisors with available capacity`);

  if (supervisors.length === 0) {
    return {
      success: false,
      assignedCount: 0,
      message: "No supervisors with remaining capacity",
    };
  }

  students.sort((left, right) => {
    const leftMatches = countProgramMatches(left, supervisors);
    const rightMatches = countProgramMatches(right, supervisors);

    if (leftMatches !== rightMatches) {
      return leftMatches - rightMatches;
    }

    return normalizeComparable(left.program).localeCompare(
      normalizeComparable(right.program),
    );
  });

  const assignments: Array<{ studentId: string; supervisorId: string; reason: string }> = [];

  for (const student of students) {
    let bestSupervisor: SupervisorAssignmentState | null = null;
    let bestScore = Number.NEGATIVE_INFINITY;

    for (const supervisor of supervisors) {
      if (supervisor.currentLoad >= supervisor.maxStudents) {
        continue;
      }

      const score = calculateSupervisorScore(
        supervisor,
        student,
        distributions,
      );

      if (score > bestScore) {
        bestScore = score;
        bestSupervisor = supervisor;
      }
    }

    if (!bestSupervisor) {
      console.warn(`[ASSIGN] No supervisor available for student ${student.id}`);
      continue;
    }

    assignments.push({
      studentId: student.id,
      supervisorId: bestSupervisor.id,
      reason:
        `Score ${bestScore.toFixed(1)} | ` +
        `load ${bestSupervisor.currentLoad}/${bestSupervisor.maxStudents} | ` +
        `program ${student.program}` +
        (student.gender != null ? ` | gender ${student.gender}` : ""),
    });

    bestSupervisor.currentLoad += 1;
    updateDistributionAfterAssignment(
      distributions,
      bestSupervisor.id,
      student,
    );

    console.log(
      `[ASSIGN] Assigned student ${student.id} to supervisor ${bestSupervisor.id} (score: ${bestScore.toFixed(1)})`,
    );
  }

  console.log(`[ASSIGN] Total assignments to commit: ${assignments.length}`);

  if (assignments.length === 0) {
    return {
      success: false,
      assignedCount: 0,
      message: "No assignments made - all supervisors at capacity",
    };
  }

  const batch = firestore.batch();

  for (const assignment of assignments) {
    batch.update(firestore.collection("students").doc(assignment.studentId), {
      currentSupervisorId: assignment.supervisorId,
      assignedAt: admin.firestore.FieldValue.serverTimestamp(),
      assignedBy: callerUid,
      assignmentMethod: "auto",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    batch.update(firestore.collection("supervisorProfiles").doc(assignment.supervisorId), {
      currentLoad: admin.firestore.FieldValue.increment(1),
      assignedStudentIds: admin.firestore.FieldValue.arrayUnion(assignment.studentId),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  try {
    await batch.commit();
    console.log(`[ASSIGN] Successfully committed ${assignments.length} assignments`);
  } catch (error) {
    console.error("[ASSIGN] Error committing:", error);
    throw new functions.https.HttpsError(
      "internal",
      `Failed to commit: ${error}`,
    );
  }

  return {
    success: true,
    assignedCount: assignments.length,
    message: `Successfully assigned ${assignments.length} students`,
    details: assignments.map((assignment) => ({
      studentId: assignment.studentId,
      supervisorId: assignment.supervisorId,
      reason: assignment.reason,
    })),
  };
}
