import { EazoProvider } from "@eazo/sdk/react";
import { I18nProvider } from "@/components/i18n/i18n-provider";
import { UserSyncEffect } from "@/components/user-profile/user-sync-effect";

const title = process.env.NEXT_PUBLIC_APP_TITLE;
const description = process.env.NEXT_PUBLIC_APP_DESCRIPTION;

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
