"use client";

import { useState } from "react";

export default function Page() {
  const [locale, setLocale] = useState<"en-US" | "zh-CN">("en-US");
  const ready = locale === "en-US" ? "Ready" : "就绪";
  const begin = locale === "en-US" ? "Begin" : "开始";
  const language = locale === "en-US" ? "中文" : "EN";

  return (
    <main className="min-h-[100dvh] transition-colors duration-200 motion-reduce:transition-none">
      <p>{ready}</p>
      <button
        data-control-id="home-start-session"
        onClick={() => console.log("session started")}
        className="transition-transform duration-150 active:scale-95 motion-reduce:transition-none"
      >
        {begin}
      </button>
      <button
        data-control-id="global-language-toggle"
        onClick={() => setLocale(locale === "en-US" ? "zh-CN" : "en-US")}
        className="transition-opacity duration-150 motion-reduce:transition-none"
      >
        {language}
      </button>
    </main>
  );
}
