export const formatFutureDate = (dateStr: string, includeTime: boolean = false): string => {
  const date = new Date(dateStr)
  date.setFullYear(date.getFullYear() + 100)

  const options: Intl.DateTimeFormatOptions = {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  }

  if (includeTime) {
    return date.toLocaleDateString('en-US', options) + ` at ${date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false })}`
  }

  return date.toLocaleDateString('en-US', options)
}
