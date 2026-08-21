// Hotwire entrypoint — loaded ONLY by layouts/hotwire.html.erb.
// Isolation rule: the React SPA (application.tsx) must never load Turbo,
// and Hotwire pages never mount React. Cross-stack navigation is a full
// page load in both directions during the migration.
import '@hotwired/turbo-rails'
import { Application } from '@hotwired/stimulus'
import { registerControllers } from 'stimulus-vite-helpers'
import { initErrorReporter } from '~/services/errorReporter'
import { initPerfCollector } from '~/utils/perfCollector'
import { startAnalyticsCollector } from '~/utils/analyticsCollector'
import { installCsrfFetch } from '~/utils/csrfFetch'

initErrorReporter()
initPerfCollector()
startAnalyticsCollector()
installCsrfFetch()

const application = Application.start()
const controllers = import.meta.glob('../controllers/**/*_controller.ts', { eager: true })
registerControllers(application, controllers)
