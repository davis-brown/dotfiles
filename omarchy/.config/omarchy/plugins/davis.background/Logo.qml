import QtQuick
import QtQuick.Shapes

// Animated Tokyo Night sigil: counter-rotating rings around a reactor core.
// Glow is faked with wide, faint strokes under each line rather than a blur
// shader, and only rotation, scale and opacity animate, so shapes are never
// re-tessellated. Motion is driven by one clock ticking at `fps` instead of
// Qt animations, which would redraw at the full display refresh rate.
Item {
  id: root

  // Set false to freeze every animation in place, e.g. while windows cover
  // the logo; a paused scene stops redrawing entirely.
  property bool animating: true
  property int fps: 30

  // Milliseconds of animated time; only advances while animating.
  property real clock: 0
  // Radians through the reactor's 4.8s breathing cycle.
  readonly property real phase: 2 * Math.PI * (clock % 4800) / 4800

  Timer {
    interval: Math.round(1000 / root.fps)
    repeat: true
    running: root.animating
    onTriggered: root.clock += interval
  }

  readonly property color bg: "#1a1b26"
  readonly property color bgDeep: "#0e0e14"
  readonly property color surface: "#24283b"
  readonly property color muted: "#414868"
  readonly property color comment: "#565f89"
  readonly property color blue: "#7aa2f7"
  readonly property color magenta: "#bb9af7"
  readonly property color cyan: "#7dcfff"

  readonly property real size: Math.min(width, height) * 0.5
  readonly property real r: size / 2

  // Backdrop: theme background with a soft indigo bloom behind the logo.
  Rectangle {
    anchors.fill: parent
    color: root.bgDeep
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: "transparent"
      fillGradient: RadialGradient {
        centerX: root.width / 2; centerY: root.height / 2
        focalX: centerX; focalY: centerY
        centerRadius: Math.max(root.width, root.height) * 0.62
        focalRadius: 0
        GradientStop { position: 0.0; color: root.surface }
        GradientStop { position: 0.45; color: root.bg }
        GradientStop { position: 1.0; color: root.bgDeep }
      }
      startX: 0; startY: 0
      PathLine { x: root.width; y: 0 }
      PathLine { x: root.width; y: root.height }
      PathLine { x: 0; y: root.height }
      PathLine { x: 0; y: 0 }
    }
  }

  // A square centered on screen that spins its children forever.
  component Spinner: Item {
    id: spinner
    property int period: 60000
    property bool reverse: false
    default property alias content: canvas.data

    anchors.centerIn: parent
    width: root.size * 1.25
    height: width

    Item {
      id: canvas
      anchors.fill: parent
    }

    rotation: (spinner.reverse ? -360 : 360) * (root.clock % spinner.period) / spinner.period
  }

  component Ring: Shape {
    id: ring
    property real radius: root.r
    property color stroke: root.blue
    property real thickness: 2
    property real start: 0
    property real sweep: 360
    property var dashes: []
    property bool glow: true

    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: ring.glow ? Qt.alpha(ring.stroke, 0.06) : "transparent"
      strokeWidth: ring.thickness * 7
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      PathAngleArc {
        centerX: root.size * 0.625; centerY: centerX
        radiusX: ring.radius; radiusY: ring.radius
        startAngle: ring.start; sweepAngle: ring.sweep
      }
    }
    ShapePath {
      strokeColor: ring.glow ? Qt.alpha(ring.stroke, 0.16) : "transparent"
      strokeWidth: ring.thickness * 3
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      PathAngleArc {
        centerX: root.size * 0.625; centerY: centerX
        radiusX: ring.radius; radiusY: ring.radius
        startAngle: ring.start; sweepAngle: ring.sweep
      }
    }
    ShapePath {
      strokeColor: ring.stroke
      strokeWidth: ring.thickness
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      strokeStyle: ring.dashes.length ? ShapePath.DashLine : ShapePath.SolidLine
      dashPattern: ring.dashes.length ? ring.dashes : [1, 0]
      PathAngleArc {
        centerX: root.size * 0.625; centerY: centerX
        radiusX: ring.radius; radiusY: ring.radius
        startAngle: ring.start; sweepAngle: ring.sweep
      }
    }
  }

  // A glowing dot riding a spinner at the given radius and angle.
  component Satellite: Item {
    property real orbit: root.r
    property real angle: 0
    property real diameter: root.r * 0.04
    property color tint: root.cyan

    anchors.fill: parent
    rotation: angle
    Repeater {
      model: [[4, 0.07], [2.2, 0.18], [1, 1.0]]
      Rectangle {
        required property var modelData
        width: diameter * modelData[0]; height: width; radius: width / 2
        color: Qt.alpha(tint, modelData[1])
        x: root.size * 0.625 - width / 2
        y: root.size * 0.625 - orbit - height / 2
      }
    }
  }

  // Bloom behind the core that breathes.
  Shape {
    id: halo
    anchors.centerIn: parent
    width: root.size * 1.25
    height: width
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: "transparent"
      fillGradient: RadialGradient {
        centerX: halo.width / 2; centerY: centerX
        focalX: centerX; focalY: centerY
        centerRadius: root.r * 0.75
        focalRadius: 0
        GradientStop { position: 0.0; color: Qt.alpha(root.blue, 0.28) }
        GradientStop { position: 0.5; color: Qt.alpha(root.magenta, 0.10) }
        GradientStop { position: 1.0; color: "transparent" }
      }
      PathAngleArc {
        centerX: halo.width / 2; centerY: centerX
        radiusX: root.r * 0.75; radiusY: radiusX
        startAngle: 0; sweepAngle: 360
      }
    }
    // Breathes between 0.55 and 1.0 every 6.4s.
    opacity: 0.775 - 0.225 * Math.cos(2 * Math.PI * (root.clock % 6400) / 6400)
  }

  // Outer dial: hairline with tick marks, majors every 30 degrees.
  Spinner {
    period: 240000
    Ring { radius: root.r * 0.98; stroke: root.muted; thickness: 1; glow: false }
    Repeater {
      model: 72
      Rectangle {
        required property int index
        readonly property bool major: index % 6 === 0
        width: major ? 3 : 1.5
        height: major ? root.r * 0.07 : root.r * 0.035
        radius: width / 2
        color: major ? root.blue : root.comment
        x: root.size * 0.625 - width / 2
        y: root.size * 0.625 - root.r * 0.98 + 4
        transform: Rotation {
          origin.x: width / 2
          origin.y: root.r * 0.98 - 4
          angle: index * 5
        }
      }
    }
  }

  // Three heavy arcs, counter-rotating.
  Spinner {
    period: 70000
    reverse: true
    Ring { radius: root.r * 0.84; stroke: root.blue; thickness: 5; start: -80; sweep: 70 }
    Ring { radius: root.r * 0.84; stroke: root.blue; thickness: 5; start: 40; sweep: 70 }
    Ring { radius: root.r * 0.84; stroke: root.blue; thickness: 5; start: 160; sweep: 70 }
    Ring { radius: root.r * 0.78; stroke: root.comment; thickness: 1; glow: false }
  }

  // Dashed data ring.
  Spinner {
    period: 32000
    Ring { radius: root.r * 0.70; stroke: root.magenta; thickness: 2; dashes: [2, 5] }
  }

  // Satellite.
  Spinner {
    period: 15000
    reverse: true
    Satellite { orbit: root.r * 0.70; angle: 180; diameter: root.r * 0.035; tint: root.magenta }
  }

  // Reactor core: a dark disc with concentric rings that breathe in sequence
  // around a pulsing node. Scale and opacity are the only animated values.
  component Pulse: Item {
    property real delay: 0
    property real amount: 0.04
    readonly property real wave: Math.sin(root.phase - delay)

    anchors.centerIn: parent
    width: root.size * 1.25
    height: width
    scale: 1 + amount * wave
    opacity: 0.75 + 0.25 * wave
  }

  Item {
    anchors.centerIn: parent
    width: root.size * 1.25
    height: width
    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeColor: "transparent"
        fillColor: Qt.alpha(root.surface, 0.55)
        PathAngleArc {
          centerX: root.size * 0.625; centerY: centerX
          radiusX: root.r * 0.5; radiusY: radiusX
          startAngle: 0; sweepAngle: 360
        }
      }
    }
  }

  Pulse {
    delay: 0
    amount: 0.02
    Ring { radius: root.r * 0.5; stroke: root.cyan; thickness: 1.5 }
  }

  Pulse {
    delay: 0.8
    amount: 0.035
    Ring { radius: root.r * 0.36; stroke: root.blue; thickness: 3 }
  }

  Pulse {
    delay: 1.6
    amount: 0.05
    Ring { radius: root.r * 0.23; stroke: root.cyan; thickness: 4 }
  }

  Pulse {
    delay: 2.4
    amount: 0.15
    Satellite { orbit: 0; diameter: root.r * 0.12; tint: root.cyan }
    Satellite { orbit: 0; diameter: root.r * 0.05; tint: "#c0caf5" }
  }
}
