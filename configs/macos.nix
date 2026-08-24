{ ... }:
{

    system.defaults = {
        NSGlobalDomain = {
            #Appearance
            AppleInterfaceStyle = "Dark";
            AppleInterfaceStyleSwitchesAutomatically = true;

            #Hide Menu Bar
            _HIHideMenuBar = true;
            _HIHideMenuBarOnFullScreen = false;

            #Scrollbars
            AppleShowScrollBars = "WhenScrolling";
        };

        dock = {
            autohide = true;

            largesize = 109;
            magnification = true;
            orientation = "right";
            show-recents = false;
            tilesize = 48;
            showAppExposeGestureEnabled = true;
            auto-hide-delay = 0.0;
            auto-hide-time-modifier = 0.2;

            wvous-br-corner = 14;
        };

        finder = {
            AppleShowAllFiles = true;
            AppleShowAllFiles = true;

            ShowPathbar = true;
            ShowStatusBar = true;

            FXPreferredViewStyle = "Nlsv";
            FXEnableExtensionChangeWarning = false;

            CreateDesktop = false;
        };

        trackpad = {
            ActuateDetents = true;
            ActuationStrength = 1;

            Clicking = false;
            DragLock = false;
            Dragging = false;

            FirstClickThreshold = 2;
            ForceSuppressed = false;
            SecondClickThreshold = 2;

            TrackpadCornerSecondaryClick = 0;

            TrackpadFiveFingerPinchGesture = 2;
            TrackpadFourFingerHorizSwipeGesture = 2;
            TrackpadFourFingerPinchGesture = 2;

            TrackpadMomentumScroll = true;
            TrackpadPinch = true;
            TrackpadRightClick = true;
            TrackpadRotate = true;

            TrackpadThreeFingerDrag = false;
            TrackpadThreeFingerHorizSwipeGesture = 2;
            TrackpadThreeFingerTapGesture = 0;
            TrackpadThreeFingerVertSwipeGesture = 2;

            TrackpadTwoFingerDoubleTapGesture = true;
            TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
        };

        WindowManager = {
            EnableStandardClickToShowDesktop = false;
            EnableTiledWindowDragging = true;
            EnableTiledWindowMargin = false;
        };

        #Accent Color or other custom preferences can be set here
        CustomUserPreferences = {
            ".GlobalPreferences" = {
                AppleAccentColor = 5;
            };
        };
    };
}