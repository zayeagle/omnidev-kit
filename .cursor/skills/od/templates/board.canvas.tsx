/**
 * OmniDev Flow Board — Cursor Canvas template (shipped in skills/od/templates).
 * Agent materializes a copy under the workspace canvases/ dir when board_cursor_canvas is true.
 * Buttons emit Signal A via newComposerChat — they do not execute phases locally.
 */
import {
  Button,
  Callout,
  Card,
  CardBody,
  CardHeader,
  Checkbox,
  Divider,
  Grid,
  H1,
  Pill,
  Row,
  Stack,
  Stat,
  Text,
  TodoListCard,
  Toggle,
  useCanvasAction,
  useCanvasState,
} from "cursor/canvas";

type PhaseId = 0 | 1 | 2 | 3 | 4 | 5;
type RunMode = "manual" | "auto";

type PhaseDef = { id: PhaseId; name: string; required: boolean };

const PHASES: PhaseDef[] = [
  { id: 0, name: "0 Assessment", required: true },
  { id: 1, name: "1 Blueprint", required: false },
  { id: 2, name: "2 Planning", required: false },
  { id: 3, name: "3 Development", required: true },
  { id: 4, name: "4 Testing", required: false },
  { id: 5, name: "5 Deploy", required: false },
];

function skipArg(enabled: Record<string, boolean>): string {
  const skipped = PHASES.filter((p) => !p.required && !enabled[String(p.id)]).map((p) => p.id);
  return skipped.length ? skipped.join(",") : "none";
}

function startPrompt(mode: RunMode, enabled: Record<string, boolean>): string {
  const skip = skipArg(enabled);
  if (mode === "auto") {
    return skip === "none" ? "/od auto" : `/od board run --skip ${skip}`;
  }
  return `/od board start --mode manual --skip ${skip}`;
}

export default function OmniDevBoardTemplate() {
  const dispatch = useCanvasAction();
  const [mode, setMode] = useCanvasState<RunMode>("runMode", "manual");
  const [started, setStarted] = useCanvasState<boolean>("started", false);
  const [enabled, setEnabled] = useCanvasState<Record<string, boolean>>("phaseEnabled", {
    "0": true,
    "1": true,
    "2": true,
    "3": true,
    "4": true,
    "5": true,
  });

  const todos = PHASES.map((p) => {
    const on = p.required || enabled[String(p.id)];
    return {
      id: `p${p.id}`,
      content: `${p.name}${!on ? " · skip" : ""}`,
      status: (!on ? "cancelled" : started && p.id === 0 ? "in_progress" : "pending") as
        | "cancelled"
        | "in_progress"
        | "pending",
    };
  });

  function togglePhase(id: PhaseId, checked: boolean) {
    const phase = PHASES.find((p) => p.id === id);
    if (!phase || phase.required || started) return;
    setEnabled((prev) => ({ ...prev, [String(id)]: checked }));
  }

  function onStart() {
    setStarted(true);
    dispatch({ type: "newComposerChat", userPrompt: startPrompt(mode, enabled) });
  }

  function onNext() {
    dispatch({ type: "newComposerChat", userPrompt: "/od board next" });
  }

  return (
    <Stack gap={24} style={{ padding: 24, maxWidth: 920 }}>
      <Stack gap={8}>
        <H1>OmniDev Flow Board</H1>
        <Text tone="secondary">
          Default manual. Full autopilot: /od auto (hard gates ask once, then continues).
        </Text>
      </Stack>

      <Grid columns={2} gap={12}>
        <Stat value={mode === "manual" ? "manual" : "auto"} label="Mode" tone="info" />
        <Stat value={started ? "started" : "idle"} label="Local preview" />
      </Grid>

      <Callout tone="warning" title="Install-integrated control plane">
        This Canvas is a Cursor shell. Codex/Claude use popup wizards against the same
        flow-board.json. Prefer /od auto for full autopilot; or /od board start.
      </Callout>

      <Grid columns={2} gap={16}>
        <Card>
          <CardHeader>Setup</CardHeader>
          <CardBody>
            <Stack gap={12}>
              <Row gap={12} align="center">
                <Toggle
                  checked={mode === "auto"}
                  disabled={started}
                  onChange={(on) => setMode(on ? "auto" : "manual")}
                />
                <Text>{mode === "auto" ? "Auto full flow" : "Manual step-by-step (default)"}</Text>
              </Row>
              <Divider />
              {PHASES.map((p) => (
                <div key={p.id}>
                  <Checkbox
                    checked={p.required || !!enabled[String(p.id)]}
                    disabled={p.required || started}
                    label={`${p.name}${p.required ? " · required" : ""}`}
                    onChange={(checked) => togglePhase(p.id, checked)}
                  />
                </div>
              ))}
            </Stack>
          </CardBody>
        </Card>

        <Stack gap={16}>
          <TodoListCard todos={todos} defaultExpanded />
          <Card>
            <CardHeader>Actions</CardHeader>
            <CardBody>
              <Stack gap={10}>
                <Button variant="primary" disabled={started} onClick={onStart}>
                  Start
                </Button>
                <Button disabled={!started || mode !== "manual"} onClick={onNext}>
                  Next (manual)
                </Button>
                <Text size="small" style={{ fontFamily: "monospace" }}>
                  {startPrompt(mode, enabled)}
                </Text>
                <Row gap={8}>
                  <Pill active>default: manual</Pill>
                  <Pill active>start = only entry</Pill>
                </Row>
              </Stack>
            </CardBody>
          </Card>
        </Stack>
      </Grid>
    </Stack>
  );
}
