// GridHackr::ROLE_LEVELS mirror for the Uplink controllers that reveal
// moderation controls client-side (packet, members): broadcast markup is
// viewer-neutral, so who outranks whom is decided from the layout's
// current-hackr-role meta. Cosmetic only — the server re-checks every
// action. Unknown or missing roles rank below operative, as on the server.

const LEVELS = { operative: 1, operator: 2, admin: 3 } as const

export function roleLevel (role: string | null | undefined): number {
  return (LEVELS as Record<string, number | undefined>)[role ?? ''] ?? 0
}

export function isModerator (role: string | null | undefined): boolean {
  return roleLevel(role) >= LEVELS.operator
}

// Strictly higher: nobody moderates a peer, a superior or themselves.
export function outranks (viewerRole: string | null | undefined, targetRole: string | null | undefined): boolean {
  return roleLevel(viewerRole) > roleLevel(targetRole)
}
