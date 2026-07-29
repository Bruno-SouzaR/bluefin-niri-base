# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Base Image: Otimizada para Intel Lunar Lake (Core Ultra 258V)
FROM ghcr.io/ublue-os/bluefin-whe:latest

### CUSTOM PACKAGES & COMPOSITOR (Niri + Ghostty + Wayland Tools)
RUN dnf copr enable -y yalter/niri && \
    dnf copr enable -y pgevor/ghostty && \
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
    # Dependências para compilação do qylock
    git \
    gcc \
    clang \
    cargo \
    rust \
    pam-devel \
    wayland-devel \
    wayland-protocols-devel \
    libxkbcommon-devel \
    pkgconf-pkg-config && \
    # Compilação e Instalação do qylock a partir do GitHub
    git clone https://github.com/Darkkal44/qylock.git /tmp/qylock && \
    cd /tmp/qylock && \
    if [ -f "Cargo.toml" ]; then \
        cargo build --release && \
        cp target/release/qylock /usr/bin/ ; \
    elif [ -f "meson.build" ]; then \
        meson setup build && ninja -C build install ; \
    elif [ -f "Makefile" ] || [ -f "CMakeLists.txt" ]; then \
        make && make install ; \
    fi && \
    # Configuração de permissões PAM para autenticação de desbloqueio de tela
    ( [ -f "pam/qylock" ] && cp pam/qylock /etc/pam.d/qylock || \
      [ -f "qylock.pam" ] && cp qylock.pam /etc/pam.d/qylock || \
      echo -e "auth include system-auth\naccount include system-auth\npassword include system-auth\nsession include system-auth" > /etc/pam.d/qylock ) && \
    # Limpeza de binários e caches de compilação
    rm -rf /tmp/qylock ~/.cargo && \
    dnf clean all

### MODIFICATIONS
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
RUN bootc container lint