export interface CodeRepository {
  name: string
  full_name: string
  slug: string
  description: string | null
  language: string | null
  default_branch: string | null
  homepage: string | null
  stargazers_count: number
  size_kb: number
  github_pushed_at: string | null
  last_synced_at: string | null
}

export interface TreeEntry {
  name: string
  path: string
  type: 'tree' | 'blob'
}

export interface TreeResponse {
  repo: CodeRepository
  path: string
  tree: TreeEntry[]
}

export interface BlobResponse {
  repo: CodeRepository
  path: string
  name: string
  content: string
  size: number
  language: string
}

export interface RepoDetailResponse {
  repo: CodeRepository
  tree: TreeEntry[]
}
