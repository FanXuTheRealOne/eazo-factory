const title = process.env.NEXT_PUBLIC_APP_TITLE;
const description = process.env.NEXT_PUBLIC_APP_DESCRIPTION;

export function I18nProvider({ children }: { children: React.ReactNode }) {
  return children;
}

export function EazoProvider({ children }: { children: React.ReactNode }) {
  return children;
}

export function UserSyncEffect() {
  return null;
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" data-title={title} data-description={description}>
      <body>
        <I18nProvider>
          <EazoProvider>
            <UserSyncEffect />
            {children}
          </EazoProvider>
        </I18nProvider>
      </body>
    </html>
  );
}
