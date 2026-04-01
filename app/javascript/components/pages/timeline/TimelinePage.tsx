import React, { useState, useRef, useEffect, useMemo, useCallback } from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { useMobileDetect } from '~/hooks/useMobileDetect'
import { ERA_MAP, eventsByEra } from './timelineData'
import type { EraKey, TimelineEvent } from './timelineData'
import { TimelineNav } from './TimelineNav'
import { TimelineEraSection } from './TimelineEraSection'
import { TimelineGap } from './TimelineGap'

export const TimelinePage: React.FC = () => {
  const { isMobile } = useMobileDetect()
  const [activeEra, setActiveEra] = useState<EraKey>('listeners')
  const eraRefs = useRef<Partial<Record<EraKey, HTMLDivElement | null>>>({})

  // Group events by era
  const eraEvents = useMemo(() => {
    const grouped: Record<EraKey, TimelineEvent[]> = {
      listeners: eventsByEra('listeners'),
      the_trade: eventsByEra('the_trade'),
      the_efficiency: eventsByEra('the_efficiency'),
      govcorp_ride: eventsByEra('govcorp_ride'),
      the_fracture: eventsByEra('the_fracture'),
      fracture_network: eventsByEra('fracture_network')
    }
    return grouped
  }, [])

  // IntersectionObserver to track active era
  // We track all currently-visible sections, then pick the one furthest down
  // the page (highest top value still in the root margin window) — that's the
  // section the user has scrolled into most recently.
  useEffect(() => {
    const visible = new Map<string, IntersectionObserverEntry>()

    const observer = new IntersectionObserver(
      entries => {
        for (const entry of entries) {
          const id = entry.target.id
          if (entry.isIntersecting) {
            visible.set(id, entry)
          } else {
            visible.delete(id)
          }
        }

        // Pick the section whose top is closest to (but below) the root margin top edge.
        // That's the one the user is currently reading.
        let best: string | null = null
        let bestTop = -Infinity
        for (const [id, entry] of visible) {
          if (entry.boundingClientRect.top > bestTop) {
            bestTop = entry.boundingClientRect.top
            best = id
          }
        }
        if (best) setActiveEra(best as EraKey)
      },
      { rootMargin: '-80px 0px -70% 0px', threshold: [0, 0.1, 0.3] }
    )

    for (const ref of Object.values(eraRefs.current)) {
      if (ref) observer.observe(ref)
    }

    return () => observer.disconnect()
  }, [])

  // Scroll to era
  const scrollToEra = useCallback((key: EraKey) => {
    const el = eraRefs.current[key]
    if (el) {
      const offset = isMobile ? 50 : 0
      const top = el.getBoundingClientRect().top + window.scrollY - offset
      window.scrollTo({ top, behavior: 'smooth' })
    }
  }, [isMobile])

  // Hash-based deep linking on mount
  useEffect(() => {
    const hash = window.location.hash.replace('#', '')
    if (hash) {
      // Allow DOM to render before scrolling
      const timeout = setTimeout(() => {
        const key = hash.replace(/-/g, '_') as EraKey
        if (eraRefs.current[key]) {
          scrollToEra(key)
        }
      }, 100)
      return () => clearTimeout(timeout)
    }
  }, [scrollToEra])

  const setEraRef = useCallback((key: EraKey) => (el: HTMLDivElement | null) => {
    eraRefs.current[key] = el
  }, [])

  // Rendering order: Listeners → Gap (with PRISM anchor) → GovCorp & RIDE → The Fracture → Fracture Network
  // The Trade and The Efficiency don't get their own full sections — they're part of the Gap.
  // The Efficiency's single event (PRISM) is rendered inside the Gap component.

  return (
    <DefaultLayout showAsciiArt={false}>
      <div style={{
        maxWidth: isMobile ? '100%' : '800px',
        margin: '0 auto',
        padding: isMobile ? '0 12px 60px' : '0 24px 80px',
        marginLeft: isMobile ? 'auto' : 'max(auto, 220px)',
        position: 'relative'
      }}>
        {/* Page header */}
        <div style={{
          textAlign: 'center',
          padding: isMobile ? '30px 16px 20px' : '50px 24px 30px'
        }}>
          <h1 style={{
            fontSize: isMobile ? '1.4em' : '1.8em',
            color: '#e5e7eb',
            margin: '0 0 8px 0',
            letterSpacing: '2px',
            fontWeight: 'bold'
          }}>
            THE TIMELINE
          </h1>
          <p style={{
            color: '#6b7280',
            fontSize: '0.85em',
            margin: 0,
            fontStyle: 'italic'
          }}>
            A living archive of THE.CYBERPUL.SE universe &mdash; 2024 through 2126
          </p>
        </div>

        {/* Navigation */}
        <TimelineNav activeEra={activeEra} onEraClick={scrollToEra} isMobile={isMobile} />

        {/* Era 1: The Listeners */}
        <TimelineEraSection
          ref={setEraRef('listeners')}
          era={ERA_MAP.listeners}
          events={eraEvents.listeners}
          isMobile={isMobile}
        />

        {/* The Trade (atmospheric header only) */}
        <TimelineEraSection
          ref={setEraRef('the_trade')}
          era={ERA_MAP.the_trade}
          events={[]}
          isMobile={isMobile}
        />

        {/* The 82-year gap with PRISM anchor */}
        <TimelineGap isMobile={isMobile} />

        {/* Era 3: The Efficiency (header only — its sole event is in the gap) */}
        <TimelineEraSection
          ref={setEraRef('the_efficiency')}
          era={ERA_MAP.the_efficiency}
          events={[]}
          isMobile={isMobile}
        />

        {/* Era 4: GovCorp & The RIDE */}
        <TimelineEraSection
          ref={setEraRef('govcorp_ride')}
          era={ERA_MAP.govcorp_ride}
          events={eraEvents.govcorp_ride}
          isMobile={isMobile}
        />

        {/* Era 5: The Fracture */}
        <TimelineEraSection
          ref={setEraRef('the_fracture')}
          era={ERA_MAP.the_fracture}
          events={eraEvents.the_fracture}
          isMobile={isMobile}
        />

        {/* Era 6: The Fracture Network */}
        <TimelineEraSection
          ref={setEraRef('fracture_network')}
          era={ERA_MAP.fracture_network}
          events={eraEvents.fracture_network}
          isMobile={isMobile}
        />

        {/* End marker */}
        <div style={{
          textAlign: 'center',
          padding: '40px 0 20px',
          color: '#374151',
          fontSize: '0.8em',
          letterSpacing: '2px'
        }}>
          SIGNAL CONTINUES...
        </div>
      </div>
    </DefaultLayout>
  )
}

export default TimelinePage
