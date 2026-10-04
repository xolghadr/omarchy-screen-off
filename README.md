# Screen off

Turns the displays off after you go idle, and leaves the session lock to Omarchy.

The default wait is 10 minutes. Stay awake (`Super + Ctrl + I`) holds this and the lock. A key or mouse move turns the displays back on.

It runs inside `omarchy-shell`. It does not write `shell.json`, and it installs nothing else.

## Install

```sh
omarchy plugin add https://github.com/xolghadr/omarchy-screen-off.git --enable
omarchy restart shell
```

## Configure

The wait is `timeout` on this plugin's entry in `~/.config/omarchy/shell.json`, in seconds from the start of idle. `0` disables blanking. Omarchy still locks on `idle.lock`.

```json
{
  "plugins": [
    {
      "id": "xolghadr.screen-off",
      "timeout": 600
    }
  ]
}
```

Set `idle.lock` later than `timeout` if the displays should go dark before the lock. With the default, a lock at 900 seconds is five minutes after the screens turn off.

```sh
omarchy-shell screen-off status
```

## Remove

```sh
omarchy plugin remove xolghadr.screen-off
```

## Dependencies

None beyond Omarchy. Blanking uses `omarchy-brightness-display` and `omarchy-brightness-keyboard`. Waking uses `omarchy-system-wake`.

## License

MIT. See [LICENSE](LICENSE).
