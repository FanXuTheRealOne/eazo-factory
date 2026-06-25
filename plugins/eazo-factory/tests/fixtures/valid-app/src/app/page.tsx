export default function Page() {
  return (
    <main>
      <button
        data-control-id="home-start-session"
        onClick={() => console.log("session started")}
      >
        Begin
      </button>
    </main>
  );
}
