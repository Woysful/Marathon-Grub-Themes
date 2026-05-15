# Marathon Grub Themes
Marathon styled set of themes for GRUB bootloader

![](https://github.com/user-attachments/assets/ea8bc33e-3ab7-476b-b71b-3df57b944d2b)

# Install
> Each theme supports three display resolutions: `1600x900` `1920x1080` `2560x1440`.
> If you are using a display with a different resolution and aspect ratio, or if your GRUB simply does not support these resolutions, these themes will not display correctly.

To install, you need to:
1. Download and extract the theme you liked.
2. Copy the theme to `/usr/share/grub/themes/`
3. In the `/etc/default/grub` file, uncomment the `GRUB_THEME` line and enter the path to `theme_[size].txt`
4. Update the Grub configuration file: `sudo grub-mkconfig -o /boot/grub/grub.cfg`
