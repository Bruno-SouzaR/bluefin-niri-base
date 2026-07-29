# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Base Image Oficial do Bluefin Developer Experience (Intel Lunar Lake / Core Ultra 258V)
FROM ghcr.io/ublue-os/bluefin-dx:latest

### CUSTOM PACKAGES & COMPOSITOR (Niri + Ghostty + Quickshell + Wayland Tools)
RUN dnf copr enable -y yalter/niri && \
    dnf copr enable -y scottames/ghostty && \
    dnf install -y \
    niri \
    xwayland-satellite \
    ghostty \
    waybar \
    fuzzel \
    mako \
    grim \
    slurp \
    wl-clipboard \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    # Engine do Quickshell e bibliotecas Qt6 para Lockscreen (Material You) / Noctalia v5
    quickshell \
    qt6-qtdeclarative \
    qt6-qt5compat \
    qt6-qtsvg \
    qt6-qtmultimedia && \
    dnf clean all

### MODIFICATIONS
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
RUN bootc container lint