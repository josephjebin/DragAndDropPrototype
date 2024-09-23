import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef MyDragAnchorStrategy = Offset Function(
    BuildContext context, Offset position);

class MyDraggable<T extends Object> extends StatefulWidget {
  final Widget child, feedback;
  final Widget? childWhenDragging;
  final MyDragAnchorStrategy dragAnchorStrategy;
  final DragEndCallback onDragEnd;
  final bool ignoringFeedbackSemantics, ignoringFeedbackPointer;

  const MyDraggable(
      {required this.child,
      required this.feedback,
      this.childWhenDragging,
      required this.dragAnchorStrategy,
      required this.onDragEnd,
      this.ignoringFeedbackSemantics = true,
      this.ignoringFeedbackPointer = true});

  @override
  State<MyDraggable> createState() => _MyDraggableState();
}

class _MyDraggableState extends State<MyDraggable> {
  bool showDefaultChild = true;
  GestureRecognizer? _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = createRecognizer(_startDrag);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasOverlay(context));
    return Listener(
      onPointerDown: (pointerDownEvent) {
        _recognizer!.addPointer(pointerDownEvent);
      },
      child: showDefaultChild ? widget.child : widget.childWhenDragging,
    );
  }

  DelayedMultiDragGestureRecognizer createRecognizer(
      GestureMultiDragStartCallback onStart) {
    return DelayedMultiDragGestureRecognizer(delay: Duration(milliseconds: 500))
      ..onStart = (Offset position) {
        final Drag? result = onStart(position);
        // if (result != null && hapticFeedbackOnStart) {
        //   HapticFeedback.selectionClick();
        // }
        return result;
      };
  }

  _MyDrag _startDrag(Offset initialPosition) {
    setState(() {
      showDefaultChild = false;
    });

    return _MyDrag(
        dragStartPoint: widget.dragAnchorStrategy(context, initialPosition),
        initialPosition: initialPosition,
        feedback: widget.feedback,
        onDragEnd: (draggableDetails) {
          setState(() {
            showDefaultChild = true;
          });
          widget.onDragEnd(draggableDetails);
        },
        overlayState:
            Overlay.of(context, debugRequiredFor: widget, rootOverlay: false),
        viewId: View.of(context).viewId,
        ignoringFeedbackSemantics: widget.ignoringFeedbackSemantics,
        ignoringFeedbackPointer: widget.ignoringFeedbackPointer);
  }
}

class _MyDrag extends Drag {
  final Offset dragStartPoint;
  final Widget feedback;
  final DragEndCallback onDragEnd;
  final OverlayState overlayState;
  final int viewId;
  final bool ignoringFeedbackSemantics;
  final bool ignoringFeedbackPointer;

  late Offset _overlayOffset;
  OverlayEntry? _entry;
  Offset _position;

  _MyDrag(
      {required this.dragStartPoint,
      required Offset initialPosition,
      required this.feedback,
      required this.onDragEnd,
      required this.overlayState,
      required this.viewId,
      required this.ignoringFeedbackSemantics,
      required this.ignoringFeedbackPointer})
      : _position = initialPosition {
    _entry = OverlayEntry(builder: _build);
    overlayState.insert(_entry!);
    updateDrag(initialPosition);
  }

  @override
  void update(DragUpdateDetails details) {
    final Offset oldPosition = _position;
    _position += Offset(0.0, details.delta.dy);
    updateDrag(_position);
  }

  @override
  void end(DragEndDetails details) {
    finishDrag(details);
  }

  @override
  void cancel() {
    _entry!.remove();
    _entry!.dispose();
    _entry = null;
  }

  Widget _build(BuildContext context) {
    return Positioned(
      left: _overlayOffset.dx,
      top: _overlayOffset.dy,
      child: ExcludeSemantics(
        excluding: ignoringFeedbackSemantics,
        child: IgnorePointer(
          ignoring: ignoringFeedbackPointer,
          child: feedback,
        ),
      ),
    );
  }

  void updateDrag(Offset globalPosition) {
    if (overlayState.mounted) {
      final RenderBox box =
          overlayState.context.findRenderObject()! as RenderBox;
      final Offset overlaySpaceOffset = box.globalToLocal(globalPosition);
      _overlayOffset = overlaySpaceOffset - dragStartPoint;


      _entry!.markNeedsBuild();
    }
  }

  void finishDrag(DragEndDetails details) {
    _entry!.remove();
    _entry!.dispose();
    _entry = null;
    onDragEnd(details as DraggableDetails);
  }
}