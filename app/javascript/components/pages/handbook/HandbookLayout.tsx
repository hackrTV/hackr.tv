import React, { type ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { useMobileDetect } from '~/hooks/useMobileDetect'
import { HandbookSidebar } from './HandbookSidebar'
import type { HandbookSection } from '~/types/handbook'

interface HandbookLayoutProps {
  sections: HandbookSection[]
  currentSectionSlug?: string
  currentArticleSlug?: string
  searchQuery: string
  onSearchChange: (q: string) => void
  children: ReactNode
}

export const HandbookLayout: React.FC<HandbookLayoutProps> = ({
  sections,
  currentSectionSlug,
  currentArticleSlug,
  searchQuery,
  onSearchChange,
  children
}) => {
  const { isDesktop } = useMobileDetect()

  return (
    <DefaultLayout showAsciiArt={false}>
      <div
        style={{
          maxWidth: '1280px',
          margin: '24px auto',
          padding: '0 16px',
          display: 'grid',
          gridTemplateColumns: isDesktop ? '280px 1fr' : '1fr',
          gap: '20px',
          alignItems: 'start'
        }}
      >
        {/* Sidebar: persistent left rail on desktop, top dropdown on mobile */}
        <aside style={{ position: isDesktop ? 'sticky' : 'static', top: isDesktop ? '16px' : undefined }}>
          {isDesktop ? (
            <HandbookSidebar
              sections={sections}
              currentSectionSlug={currentSectionSlug}
              currentArticleSlug={currentArticleSlug}
              searchQuery={searchQuery}
              onSearchChange={onSearchChange}
            />
          ) : (
            <MobileSectionSelector
              sections={sections}
              currentSectionSlug={currentSectionSlug}
              currentArticleSlug={currentArticleSlug}
            />
          )}
        </aside>

        <main>{children}</main>
      </div>
    </DefaultLayout>
  )
}

interface MobileSectionSelectorProps {
  sections: HandbookSection[]
  currentSectionSlug?: string
  currentArticleSlug?: string
}

const MobileSectionSelector: React.FC<MobileSectionSelectorProps> = ({
  sections,
  currentArticleSlug
}) => {
  const navigate = useNavigate()
  return (
    <div style={{ background: '#0d0d0d', border: '1px solid #333', padding: '12px' }}>
      <label
        htmlFor="handbook-mobile-jump"
        style={{ display: 'block', color: '#22d3ee', fontSize: '0.85em', fontWeight: 'bold', marginBottom: '6px' }}
      >
        JUMP TO ARTICLE
      </label>
      <select
        id="handbook-mobile-jump"
        value={currentArticleSlug || ''}
        onChange={(e) => {
          const slug = e.target.value
          navigate(slug ? `/handbook/${slug}` : '/handbook')
        }}
        className="tui-input"
        style={{ width: '100%', padding: '6px 8px', background: '#0a0a0a', color: '#d0d0d0', border: '1px solid #333' }}
      >
        <option value="">— Handbook Home —</option>
        {sections.map(section => (
          <optgroup key={section.slug} label={section.name}>
            {section.articles.map(article => (
              <option key={article.slug} value={article.slug}>
                {article.kind === 'tutorial' ? '▶ ' : ''}{article.title}
              </option>
            ))}
          </optgroup>
        ))}
      </select>
    </div>
  )
}
