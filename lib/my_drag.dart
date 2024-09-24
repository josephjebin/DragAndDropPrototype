import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef MyDragAnchorStrategy = Offset Function(
    BuildContext context, Offset position);
typedef _OnDrag = void Function(Offset offset);


class MyDraggable<T extends Object> extends StatefulWidget {
  final Widget child, feedback;
  final Widget? childWhenDragging;
  final MyDragAnchorStrategy dragAnchorStrategy;
  final _OnDrag onDragUpdate, onDragEnd;
  final bool ignoringFeedbackSemantics, ignoringFeedbackPointer;

  const MyDraggable(
      {required this.child,
      required this.feedback,
      this.childWhenDragging,
      required this.dragAnchorStrategy,
      required this.onDragEnd,
      required this.onDragUpdate,
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
        draggableToPointerOffset: widget.dragAnchorStrategy(context, initialPosition),
        initialPointerOffset: initialPosition,
        feedback: widget.feedback,
        onDragUpdate: (offset) {
          widget.onDragUpdate(offset); 
        }, 
        onDragEnd: (offset) {
          setState(() {
            showDefaultChild = true;
          });
          widget.onDragEnd(offset);
        },
        overlayState:
            Overlay.of(context, debugRequiredFor: widget, rootOverlay: false),
        viewId: View.of(context).viewId,
        ignoringFeedbackSemantics: widget.ignoringFeedbackSemantics,
        ignoringFeedbackPointer: widget.ignoringFeedbackPointer);
  }
}

class _MyDrag extends Drag  {
  final Offset draggableToPointerOffset, initialPointerOffset;
  final Widget feedback;
  final _OnDrag onDragUpdate, onDragEnd;
  final OverlayState overlayState;
  final int viewId;
  final bool ignoringFeedbackSemantics;
  final bool ignoringFeedbackPointer;

  late Offset _overlayOffset;
  OverlayEntry? _entry;
  Offset _pointerOffset;
  //number of five minute increments the draggable has changed
  //e.g. -1 means moved into the previous 5-minute interval (7:30 --> 7:25)
  //e.g. 3 means moved 3 5-minute intervals down (7:30 --> 7:45)
  //initialized to -1, so first call to updateDrag will update this to 0 and calculate _overlayOffset
  int deltaFiveMinuteIncrements = -1;

  _MyDrag(
      {required this.draggableToPointerOffset,
      required this.initialPointerOffset,
      required this.feedback,
      required this.onDragUpdate,
      required this.onDragEnd,
      required this.overlayState,
      required this.viewId,
      required this.ignoringFeedbackSemantics,
      required this.ignoringFeedbackPointer})
      : _pointerOffset = initialPointerOffset {
        // print('draggableToPointerOffset:$draggableToPointerOffset, pointerOffset:$_pointerOffset'); 
    _entry = OverlayEntry(builder: _build);
    overlayState.insert(_entry!);
    updateDrag(_pointerOffset);
  }

  @override
  void update(DragUpdateDetails details) {
    //not entirely accurate - we've restricted pointer offset to only move vertically 
    _pointerOffset += Offset(0.0, details.delta.dy);
    // print('_pointerOffset:$_pointerOffset'); 
    updateDrag(_pointerOffset);
    onDragUpdate(details.globalPosition); 
  }

  @override
  void end(DragEndDetails details) {
    finishDrag(details.globalPosition);
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

  void updateDrag(Offset pointerOffset) {
    // if (overlayState.mounted) {
      // final RenderBox box =
      //     overlayState.context.findRenderObject()! as RenderBox;
      // final Offset overlaySpaceOffset = box.globalToLocal(pointerOffset);
      // _overlayOffset = overlaySpaceOffset - draggableToPointerOffset;

      late int newDelta; 
      
      //moving up has different logic than moving down because you only need to move up 1 minute to go into the previous 5-minute interval.
      //you need to move down 5 minutes to go into the next 5-minute interval
      if(pointerOffset.dy < initialPointerOffset.dy) {
        //examples that show why we subtract 1 from the difference
        //e.g. 1: if you move up 1 min, you should be in the previous 5-minute interval. 
        //e.g. 2: if you move up 5 mins, you should also be in the previous 5-minute interval. 
        //e.g. 3: if you move up 6 mins, you should be -2 5-minute intervals intervals (7:30 - 6 mins = 7:24 --> should be in the 5-minute interval starting at 7:20)
        int difference = ((initialPointerOffset.dy - pointerOffset.dy - 1) / 5).truncate();
        newDelta = -1 - difference; 
      } else {
        newDelta = ((pointerOffset.dy - initialPointerOffset.dy) / 5).truncate(); 
      }

      if(newDelta != deltaFiveMinuteIncrements) {
        deltaFiveMinuteIncrements = newDelta; 
        _overlayOffset = initialPointerOffset - draggableToPointerOffset + Offset(0.0, newDelta * 5);;
        _entry!.markNeedsBuild();
      }

    // }
  }

  void finishDrag(Offset offset) {
    _entry!.remove();
    _entry!.dispose();
    _entry = null;
    onDragEnd(offset);
  }
}