# ==============================================================================
# Firefox Extensions
# ==============================================================================
# modules/home/browser/firefox/extensions.nix

{pkgs, ...}:
with pkgs.nur.repos.rycee.firefox-addons; [
  ublock-origin            # Ad blocking
  sponsorblock            # Skip sponsorship segments
  return-youtube-dislikes # Show dislikes on YouTube
  darkreader              # Dark mode
  plasma-integration      # KDE integration
  enhancer-for-youtube    # YouTube enhancements
  indie-wiki-buddy        # Wiki integration
  stylus                  # Custom CSS
  canvasblocker          # Privacy protection
]
