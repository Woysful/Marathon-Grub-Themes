# Marathon Grub Themes
Marathon styled set of themes for GRUB bootloader

![](https://github.com/user-attachments/assets/ea8bc33e-3ab7-476b-b71b-3df57b944d2b)

# Install
> Each theme supports three display resolutions: `1600x900` `1920x1080` `2560x1440`.
> If you are using a display with a different resolution and aspect ratio, or if your GRUB simply does not support these resolutions, these themes will not display correctly.

### Option 1 — Automated (recommended)
```sh
git clone https://github.com/Woysful/Marathon-Grub-Themes.git
cd Marathon-Grub-Themes
sudo ./install.sh
```

Additional flags:
- `sudo ./install.sh -y` — skip all prompts (picks first theme + resolution)
- `sudo ./install.sh --theme Marathon-MapScreen --resolution 1080p` — headless install
- `sudo ./install.sh --no-grub-update` — copy only, skip `grub-mkconfig`

### Option 2 — Manual
```sh
sudo cp -r <theme> /usr/share/grub/themes/
```
Then in `/etc/default/grub`, set:
```
GRUB_THEME="/usr/share/grub/themes/<theme>/theme_<size>.txt"
```
Finally:
```sh
sudo grub-mkconfig -o /boot/grub/grub.cfg
```
