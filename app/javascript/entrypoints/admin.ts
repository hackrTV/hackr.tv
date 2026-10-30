// Admin entrypoint — loaded ONLY by layouts/admin.html.erb. Stimulus
// alone, no Turbo: the admin is plain full-page navigation and its
// inline DOMContentLoaded scripts (sortable tables, the data-confirm
// handler) depend on that. The /root music screens (artists / releases /
// tracks) are console screens, so the home console's terminal controller
// (reveal + the "> " prompt — utils/visit.ts does a full load here), the
// hover peek and the admin-only ledger-filter / file-pick / autogrow /
// confirm-slug controllers are registered. Add a controller here when an
// admin screen needs it; the public pages register everything through
// hotwire.ts's glob.
import { Application } from '@hotwired/stimulus'
import TerminalController from '~/controllers/terminal_controller'
import PeekController from '~/controllers/peek_controller'
import LedgerFilterController from '~/controllers/ledger_filter_controller'
import FilePickController from '~/controllers/file_pick_controller'
import AutogrowController from '~/controllers/autogrow_controller'
import ConfirmSlugController from '~/controllers/confirm_slug_controller'

const application = Application.start()
application.register('terminal', TerminalController)
application.register('peek', PeekController)
application.register('ledger-filter', LedgerFilterController)
application.register('file-pick', FilePickController)
application.register('autogrow', AutogrowController)
application.register('confirm-slug', ConfirmSlugController)
