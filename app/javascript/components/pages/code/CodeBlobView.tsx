import React, { useEffect, useRef } from 'react'
import hljs from 'highlight.js'
import 'highlight.js/styles/github-dark.css'
import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'

interface CodeBlobViewProps {
  content: string
  language: string
  name: string
  size: number
}

const formatSize = (bytes: number): string => {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

export const CodeBlobView: React.FC<CodeBlobViewProps> = ({ content, language, name, size }) => {
  const codeRef = useRef<HTMLElement>(null)
  const isMarkdown = name.toLowerCase().endsWith('.md')
  const lines = content.split('\n')

  useEffect(() => {
    if (codeRef.current && !isMarkdown) {
      hljs.highlightElement(codeRef.current)
    }
  }, [content, language, isMarkdown])

  return (
    <div style={{ border: '1px solid #333', background: '#0d0d0d' }}>
      {/* File header */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '8px 14px',
        borderBottom: '1px solid #333',
        background: '#1a1a1a',
        fontSize: '0.85em',
        color: '#9ca3af'
      }}>
        <span>{lines.length} lines</span>
        <span>{formatSize(size)}</span>
      </div>

      {/* Content */}
      {isMarkdown ? (
        <div style={{
          padding: '20px 30px',
          color: '#d0d0d0',
          lineHeight: '1.7',
          fontFamily: '\'Courier New\', Courier, monospace',
          fontSize: '0.9em'
        }}>
          <div className="code-markdown-content">
            <style>{`
              .code-markdown-content h1 { color: #a78bfa; font-size: 1.4em; margin: 20px 0 10px; border-bottom: 1px solid #333; padding-bottom: 8px; }
              .code-markdown-content h2 { color: #a78bfa; font-size: 1.2em; margin: 18px 0 8px; }
              .code-markdown-content h3 { color: #a78bfa; font-size: 1.05em; margin: 14px 0 6px; }
              .code-markdown-content a { color: #818cf8; }
              .code-markdown-content code { background: #1e1e1e; padding: 2px 5px; border-radius: 3px; font-size: 0.9em; }
              .code-markdown-content pre { background: #1e1e1e; padding: 12px; overflow-x: auto; border: 1px solid #333; }
              .code-markdown-content pre code { background: none; padding: 0; }
              .code-markdown-content ul, .code-markdown-content ol { padding-left: 20px; }
              .code-markdown-content li { margin: 4px 0; }
              .code-markdown-content blockquote { border-left: 3px solid #6366f1; padding-left: 12px; color: #9ca3af; margin: 10px 0; }
              .code-markdown-content table { border-collapse: collapse; width: 100%; }
              .code-markdown-content th, .code-markdown-content td { border: 1px solid #333; padding: 6px 10px; text-align: left; }
              .code-markdown-content th { background: #1e1e1e; color: #a78bfa; }
              .code-markdown-content img { max-width: 100%; }
            `}</style>
            <ReactMarkdown remarkPlugins={[remarkGfm]}>{content}</ReactMarkdown>
          </div>
        </div>
      ) : (
        <div style={{ display: 'flex', overflow: 'auto' }}>
          {/* Line numbers */}
          <div style={{
            padding: '12px 0',
            borderRight: '1px solid #333',
            userSelect: 'none',
            minWidth: '50px',
            textAlign: 'right',
            flexShrink: 0
          }}>
            {lines.map((_, i) => (
              <div key={i} style={{
                padding: '0 10px',
                color: '#4b5563',
                fontSize: '0.85em',
                lineHeight: '1.45em',
                fontFamily: '\'Courier New\', Courier, monospace'
              }}>
                {i + 1}
              </div>
            ))}
          </div>

          {/* Code content */}
          <pre style={{
            margin: 0,
            padding: '12px 14px',
            overflow: 'auto',
            flex: 1,
            background: 'transparent'
          }}>
            <code
              ref={codeRef}
              className={`language-${language || 'plaintext'}`}
              style={{
                fontSize: '0.85em',
                lineHeight: '1.45em',
                fontFamily: '\'Courier New\', Courier, monospace',
                background: 'transparent'
              }}
            >
              {content}
            </code>
          </pre>
        </div>
      )}
    </div>
  )
}
