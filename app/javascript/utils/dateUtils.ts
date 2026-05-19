export const formatFutureDate = (dateStr: string, includeTime: boolean = false): string => {
  const date = new Date(dateStr)
  date.setFullYear(date.getFullYear() + 100)

  const options: Intl.DateTimeFormatOptions = {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  }

  if (includeTime) {
    return date.toLocaleDateString('en-US', options) + ` at ${date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true })}`
  }

  return date.toLocaleDateString('en-US', options)
}
