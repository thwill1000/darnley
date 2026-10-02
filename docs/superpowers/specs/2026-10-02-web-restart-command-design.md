# Web RESTART Command Design

## Goal

Replace the web port's current `QUIT` command with `RESTART`. Restarting must
require an explicit confirmation, with buttons labelled **YES** and **NO**.

## Behavior

- Entering `RESTART` opens a custom modal confirmation with YES and NO buttons.
- YES resets the current game state, returns to the starting room, and shows
  the intro and starting location as a fresh game.
- NO dismisses the confirmation and resumes the current game unchanged.
- The web command aliases `RESET` and `START` continue to invoke restart
  confirmation. Former quit aliases (`Q`, `DIE`, `END`, and `EXIT`) no longer
  invoke restart or exit the game.
- The command behavior change applies only to the web port. `web/data/messages.dat`
  links to `mmbasic/data/messages.dat`, so changing the shared help text also
  changes the MMBasic help text; this limited shared-data effect is accepted.

## Implementation

Use a dedicated confirmation dialog in the web UI so the button labels and
actions are explicit. Keep the game-state reset in the game loop, after the
dialog resolves positively; cancellation must not touch the state or autosave.
Update web help text to list `RESTART` rather than `QUIT`.

## Validation

Add focused tests for command parsing/dispatch, both confirmation outcomes,
and the UI dialog controls. Run the web test suite.
