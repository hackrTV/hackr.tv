import React from 'react'
import { Link } from 'react-router-dom'
import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'
import rehypeRaw from 'rehype-raw'
import rehypeSanitize from 'rehype-sanitize'
import { transformMarkdownLinks } from '~/utils/codexLinks'
import { useCodexMappings } from '~/hooks/useCodexMappings'

// Paths that are served directly by Rails (not by the React SPA) and must
// trigger a full-page navigation rather than a client-side route change.
// Keep this list small — it exists only for cross-boundary links from
// markdown content. Add a path here if an article needs to link to it and
// the SPA would otherwise 404.
const RAILS_ONLY_PATHS = [
  '/terminal',
  '/root'
]

const isRailsOnlyPath = (href: string) =>
  RAILS_ONLY_PATHS.some(p => href === p || href.startsWith(p + '/') || href.startsWith(p + '?'))

interface MarkdownContentProps {
  content: string
  accentColor?: string
}

export const MarkdownContent: React.FC<MarkdownContentProps> = ({
  content,
  accentColor = '#22d3ee'
}) => {
  const { mappings } = useCodexMappings()

  return (
    <div style={{ color: '#e5e5e5', lineHeight: '1.8', fontSize: '1.05em' }}>
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        rehypePlugins={[rehypeRaw, rehypeSanitize]}
        components={{
          h1: (props) => <h1 style={{ color: accentColor, marginTop: '30px', marginBottom: '15px', fontSize: '1.8em' }} {...props} />,
          h2: (props) => <h2 style={{ color: accentColor, marginTop: '25px', marginBottom: '12px', fontSize: '1.5em' }} {...props} />,
          h3: (props) => <h3 style={{ color: accentColor, marginTop: '20px', marginBottom: '10px', fontSize: '1.3em' }} {...props} />,
          p: (props) => <p style={{ marginBottom: '15px' }} {...props} />,
          a: ({ href, children, ...props }) => {
            const linkStyle = {
              display: 'inline' as const,
              color: '#60a5fa',
              textDecoration: 'none',
              borderBottom: '1px solid #60a5fa',
              transition: 'color 0.2s'
            }
            if (href && href.startsWith('/') && !isRailsOnlyPath(href)) {
              return (
                <Link
                  to={href}
                  style={linkStyle}
                  onMouseEnter={(e) => e.currentTarget.style.color = '#93c5fd'}
                  onMouseLeave={(e) => e.currentTarget.style.color = '#60a5fa'}
                >
                  {children}
                </Link>
              )
            }
            return (
              <a
                href={href}
                style={linkStyle}
                onMouseEnter={(e) => e.currentTarget.style.color = '#93c5fd'}
                onMouseLeave={(e) => e.currentTarget.style.color = '#60a5fa'}
                {...props}
              >
                {children}
              </a>
            )
          },
          ul: (props) => <ul style={{ marginLeft: '20px', marginBottom: '15px' }} {...props} />,
          ol: (props) => <ol style={{ marginLeft: '20px', marginBottom: '15px' }} {...props} />,
          li: (props) => <li style={{ marginBottom: '8px' }} {...props} />,
          strong: (props) => <strong style={{ color: '#fff' }} {...props} />,
          code: (props) => (
            <code
              style={{
                background: '#0a0a0a',
                padding: '2px 6px',
                borderRadius: '3px',
                fontFamily: 'monospace',
                fontSize: '0.9em',
                color: '#fbbf24'
              }}
              {...props}
            />
          ),
          pre: (props) => (
            <pre
              style={{
                background: '#0a0a0a',
                padding: '15px',
                borderRadius: '3px',
                overflow: 'auto',
                marginBottom: '15px',
                border: '1px solid #333'
              }}
              {...props}
            />
          ),
          table: (props) => (
            <table
              style={{
                width: '100%',
                borderCollapse: 'collapse',
                marginBottom: '20px',
                background: '#0a0a0a',
                border: `1px solid ${accentColor}`
              }}
              {...props}
            />
          ),
          thead: (props) => (
            <thead style={{ background: accentColor, color: '#000' }} {...props} />
          ),
          th: (props) => (
            <th
              style={{
                padding: '12px 15px',
                textAlign: 'left',
                fontWeight: 'bold',
                borderBottom: `2px solid ${accentColor}`
              }}
              {...props}
            />
          ),
          td: (props) => (
            <td style={{ padding: '10px 15px', borderBottom: '1px solid #333' }} {...props} />
          ),
          tr: (props) => (
            <tr
              style={{ transition: 'background 0.2s' }}
              onMouseEnter={(e) => e.currentTarget.style.background = '#1a1a1a'}
              onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
              {...props}
            />
          )
        }}
      >
        {transformMarkdownLinks(content, mappings)}
      </ReactMarkdown>
    </div>
  )
}
