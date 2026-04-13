export type HandbookKind = 'reference' | 'tutorial'
export type HandbookDifficulty = 'beginner' | 'intermediate' | 'advanced'

export interface HandbookArticleSummary {
  id: number
  slug: string
  title: string
  kind: HandbookKind
  difficulty: HandbookDifficulty | null
  summary: string | null
  position: number
  updated_at: string
  section?: { slug: string; name: string }
}

export interface HandbookSection {
  id: number
  slug: string
  name: string
  icon: string | null
  summary: string | null
  position: number
  articles: HandbookArticleSummary[]
}

export interface HandbookTree {
  sections: HandbookSection[]
}

export interface HandbookArticle {
  id: number
  slug: string
  title: string
  kind: HandbookKind
  difficulty: HandbookDifficulty | null
  summary: string | null
  body: string
  metadata: Record<string, unknown>
  position: number
  updated_at: string
  section: {
    id: number
    slug: string
    name: string
    icon: string | null
  }
  prev_article: { slug: string; title: string } | null
  next_article: { slug: string; title: string } | null
}
