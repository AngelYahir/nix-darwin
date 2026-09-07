{
  pkgs,
  inputs,
  ...
}:

{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    package = pkgs.yazi.override {
      yazi-unwrapped = pkgs.yazi-unwrapped.overrideAttrs (old: {
        cargoTestFlags = (old.cargoTestFlags or []) ++ [ "-p" "yazi-adapter" ];
        # Temporary compatibility patch: one placement for the entire image
        # in Zellij, including deletion when switching previews.
        patches = (old.patches or []) ++ [ (pkgs.writeText "yazi-zellij.patch" ''
--- a/yazi-adapter/src/drivers/kgp_old.rs
+++ b/yazi-adapter/src/drivers/kgp_old.rs
@@ -37,0 +38,4 @@
+		if EMULATOR.brand.get() == yazi_emulator::Brand::Zellij {
+			writef!(w, "{START}_Gq=2,a=d,d=I,i={}{ESCAPE}\\{CLOSE}", kgp_id())?;
+			return Ok(());
+		}
@@ -105,0 +110,8 @@
+	// Zellij cannot reliably render Yazi's per-cell placements.
+	fn place_whole(area: Rect, id: u32) -> Result<Vec<u8>> {
+		let mut buf = Vec::new();
+		write!(buf, "{}{START}_Gq=2,a=p,i={id},p=1,c={},r={},z=-1,C=1{ESCAPE}\\{CLOSE}",
+			MoveTo(area.x, area.y), area.width, area.height)?;
+		Ok(buf)
+	}
+
@@ -106,0 +119,3 @@
+		if EMULATOR.brand.get() == yazi_emulator::Brand::Zellij {
+			return Self::place_whole(area, kgp_id());
+		}
@@ -131,0 +147,14 @@
+
+#[cfg(test)]
+mod zellij_tests {
+	use super::*;
+
+	#[test]
+	fn whole_image_has_one_placement_covering_preview() {
+		let bytes = KgpOld::place_whole(Rect::new(10, 3, 80, 25), 42).unwrap();
+		let output = String::from_utf8(bytes).unwrap();
+		assert_eq!(output.matches("a=p").count(), 1);
+		assert!(output.contains("i=42,p=1,c=80,r=25"));
+		assert!(output.contains("\x1b[4;11H"));
+	}
+}
        '') ];
      });
    };

    settings = {
      mgr = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
      };

      # Force PDFs through Yazi's built-in PDF renderer even when `file`
      # reports a generic MIME type (common with some downloaded PDFs).
      plugin = {
        prepend_preloaders = [
          { url = "*.pdf"; run = "pdf"; }
        ];
        prepend_previewers = [
          { url = "*.pdf"; run = "pdf"; }
        ];
      };
    };

    extraPackages = with pkgs; [
      jq
      fd
      ripgrep
      fzf
      zoxide
      poppler-utils
      resvg
      imagemagick
      ffmpeg
    ];
  };
}
