import 'package:flutter/material.dart';
import 'package:hello_flutter/my_drag.dart';

void main() {
  runApp(Dragprototype());
}

class Dragprototype extends StatefulWidget {
  @override
  State<Dragprototype> createState() => _DragprototypeState();
}

class _DragprototypeState extends State<Dragprototype> {
  final ScrollController scrollController = ScrollController();
  final double hourHeight = 60;
  final double sidebarWidth = 40.0;

  // assuming 1 hour is 60 pixels, 1 min = 1 pixel
  int minutesScrolled = 0;
  List<Plan> plans = <Plan>[
    Plan(title: "wake up", start: DateTime(2024, 9, 18, 7, 30), duration: 120)
  ];
  String appBarText = "Start dragging the event / inbox task";
  final keyText = GlobalKey();
  double calendarVerticalOffset = 0.0;

  @override
  void initState() {
    scrollController.addListener(_handleScroll);
    super.initState();
    getCalendarOffset();
  }

  void getCalendarOffset() => WidgetsBinding.instance.addPostFrameCallback((_) {
        final box = keyText.currentContext?.findRenderObject() as RenderBox;
        setState(() {
          calendarVerticalOffset = box.localToGlobal(Offset.zero).dy;
          print(calendarVerticalOffset);
        });
      });

  void _handleScroll() {
    if (scrollController.offset.toInt() != minutesScrolled) {
      setState(() {
        minutesScrolled = scrollController.offset.toInt();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Center(
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
                backgroundColor: Colors.blueGrey,
                title: Text(
                  appBarText,
                  softWrap: true,
                )),
            bottomNavigationBar: InboxButton(
                scrollController: scrollController,
                calendarVerticalOffset: calendarVerticalOffset,
                setAppBarText: (value) {
                  setState(() {
                    appBarText = value;
                  });
                }),
            body: Stack(
              key: keyText,
              children: [
                Calendar(
                  hourHeight: hourHeight,
                  sidebarWidth: sidebarWidth,
                  controller: scrollController,
                ),
                CalendarDraggable(
                  plan: plans.first,
                  top: (plans.first.minutesFromMidnight - minutesScrolled)
                      .toDouble(),
                  left: sidebarWidth + 25,
                  height: plans.first.duration.toDouble(),
                  setAppBarText: (value) {
                    setState(() {
                      appBarText = value;
                    });
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Plan {
  String title;
  DateTime start;
  var minutesFromMidnight = 0;
  int duration;

  Plan({required this.title, required this.start, required this.duration}) {
    minutesFromMidnight = start
        .difference(DateTime(start.year, start.month, start.day))
        .inMinutes;
  }
}

//Calendar draggables don't need to calculate height from the top of the calendar - it already has an associated time,
//so we only need to worry about how much the calendar draggable is dragged.
class CalendarDraggable extends StatelessWidget {
  Plan plan;
  double top, left, height, width = 315.0;
  final ValueSetter<String> setAppBarText;

  CalendarDraggable(
      {super.key,
      required this.plan,
      required this.top,
      required this.left,
      required this.height,
      required this.setAppBarText});

  @override
  Widget build(BuildContext build) {
    return Positioned(
      top: top,
      left: left,
      child: CalendarLongPressDraggable(
        plan: plan,
        height: height,
        width: width,
        top: top,
        setAppBarText: setAppBarText,
      ),
    );
  }
}

class CalendarLongPressDraggable extends StatefulWidget {
  const CalendarLongPressDraggable(
      {super.key,
      required this.plan,
      required this.height,
      required this.width,
      required this.top,
      required this.setAppBarText});

  final Plan plan;
  final double height;
  final double width;
  final double top;
  final ValueSetter<String> setAppBarText;

  @override
  State<CalendarLongPressDraggable> createState() =>
      _CalendarLongPressDraggableState();
}

class _CalendarLongPressDraggableState
    extends State<CalendarLongPressDraggable> {
  var feedbackOffset = Offset.zero;
  var _deltaFiveMinuteIncrements = 0;

  Offset calendarDragAnchorStrategy(BuildContext context, Offset position) {
    final RenderBox renderObject = context.findRenderObject()! as RenderBox;
    setState(() {
      feedbackOffset = position;
    });
    return renderObject.globalToLocal(position);
  }

  @override
  Widget build(BuildContext context) {
    return MyDraggable(
        feedback: UnscheduledContainer(
          title: widget.plan.title,
          duration: widget.plan.duration,
        ),
        dragAnchorStrategy: calendarDragAnchorStrategy,
        onDragUpdate: (deltaFiveMinuteIncrements) {
          if (deltaFiveMinuteIncrements != _deltaFiveMinuteIncrements) {
            DateTime newStartTime = widget.plan.start
                .add(Duration(minutes: 5 * deltaFiveMinuteIncrements));
            widget.setAppBarText('${newStartTime.hour}:${newStartTime.minute}');
            setState(() {
              _deltaFiveMinuteIncrements = deltaFiveMinuteIncrements;
            });
          }
        },
        onDragEnd: (deltaFiveMinuteIncrements) {
          DateTime newStartTime = widget.plan.start
              .add(Duration(minutes: 5 * deltaFiveMinuteIncrements));
          widget.setAppBarText(
              'update start time to: ${newStartTime.hour}:${newStartTime.minute}');
          setState(() {
            _deltaFiveMinuteIncrements = deltaFiveMinuteIncrements;
          });
        },
        childWhenDragging: Opacity(
          opacity: .7,
          child: ScheduledContainer(
            title: widget.plan.title,
            height: widget.height,
            width: widget.width,
            start: widget.plan.start,
            duration: widget.plan.duration,
          ),
        ),
        child: ScheduledContainer(
          title: widget.plan.title,
          height: widget.height,
          width: widget.width,
          start: widget.plan.start,
          duration: widget.plan.duration,
        ));

    // return LongPressDraggable(
    //   axis: Axis.vertical,
    //   dragAnchorStrategy: calendarDragAnchorStrategy,
    //   onDragUpdate: (details) {
    //     var difference =
    //         ((details.globalPosition.dy - feedbackOffset.dy) / 5).truncate();
    //     if (difference != fiveMinuteIncrements) {
    //       setState(() {
    //         fiveMinuteIncrements = difference;
    //         widget.setAppBarText(fiveMinuteIncrements.toString());
    //       });
    //     }
    //   },
    //   onDragEnd: (details) {
    //     DateTime newStartTime =
    //         widget.plan.start.add(Duration(minutes: 5 * fiveMinuteIncrements));
    //     widget.setAppBarText(
    //         'update start time to: ${newStartTime.hour}:${newStartTime.minute}');
    //   },
    //   feedback: CalendarContainer(
    //     title: widget.plan.title,
    //     height: widget.height,
    //     width: widget.width,
    //     start: widget.plan.start.add(Duration(minutes: 5 * fiveMinuteIncrements)),
    //     duration: widget.plan.duration,
    //   ),
    //   feedbackOffset: feedbackOffset,
    //   childWhenDragging: Opacity(
    //     opacity: .7,
    //     child: CalendarContainer(
    //       title: widget.plan.title,
    //       height: widget.height,
    //       width: widget.width,
    //       start: widget.plan.start,
    //       duration: widget.plan.duration,
    //     ),
    //   ),
    //   child: CalendarContainer(
    //     title: widget.plan.title,
    //     height: widget.height,
    //     width: widget.width,
    //     start: widget.plan.start,
    //     duration: widget.plan.duration,
    //   ),
    // );
  }
}

class ScheduledContainer extends StatelessWidget {
  const ScheduledContainer(
      {super.key,
      required this.title,
      required this.height,
      required this.width,
      required this.start,
      required this.duration});

  final String title;
  final double height, width;
  final DateTime start;
  final int duration;

  @override
  Widget build(BuildContext context) {
    DateTime end = start.add(Duration(minutes: duration));

    return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
            color: Colors.blue, border: Border.all(color: Colors.black)),
        child: Text(
            style: textStyle,
            '${start.hour}:${start.minute} - ${end.hour}:${end.minute}: $title'));
  }
}

class UnscheduledContainer extends StatelessWidget {
  final String title; 
  final int duration; 

  const UnscheduledContainer({super.key, required this.title, required this.duration}); 

  @override 
  Widget build(BuildContext context) {
    return Container(
      height: duration.toDouble(), 
      width: 315.0,
      decoration: BoxDecoration(
        color: Colors.blue, border: Border.all(color: Colors.black)
      ),
      child: Text(
        style: textStyle,
        title
      )
    );
  }
}

class Task {
  String title;
  int duration;

  Task({required this.title, required this.duration});
}

class TaskDraggable extends StatefulWidget {
  Task task;
  ScrollController scrollController;
  final ValueSetter<String> setAppBarText;
  final double calendarVerticalOffset;

  TaskDraggable(
      {super.key,
      required this.task,
      required this.scrollController,
      required this.setAppBarText,
      required this.calendarVerticalOffset});

  @override
  State<TaskDraggable> createState() => _TaskDraggable();
}

class _TaskDraggable extends State<TaskDraggable> {
  DateTime start = DateTime.now();
  var _deltaFiveMinuteIncrements = 0;

  Offset taskDragAnchorStrategy(BuildContext context, Offset position) {
    final RenderBox renderObject = context.findRenderObject()! as RenderBox;
    final Offset draggableToPointerOffset =
        renderObject.globalToLocal(position);
    var topOfDraggableOffset = position - draggableToPointerOffset;
    var distanceFromTopOfDraggableToTopOfCalendar_InMinutes =
        (topOfDraggableOffset.dy - widget.calendarVerticalOffset).toInt();
    var minutesScrolled = widget.scrollController.offset.toInt();
    var topOfDraggableInMinutes =
        minutesScrolled + distanceFromTopOfDraggableToTopOfCalendar_InMinutes;
    //topOfDraggable could be 7:39, but we need it to be a multiple of 5, so calculate the remainder and shift it up by that much
    var remainder = topOfDraggableInMinutes % 5;

    setState(() {
      start = DateTime(2024)
          .add(Duration(minutes: topOfDraggableInMinutes - remainder));
      widget.setAppBarText(start.toString());
    });
    return Offset(
        draggableToPointerOffset.dx, draggableToPointerOffset.dy + remainder);
  }

  @override
  Widget build(BuildContext context) {
    return MyDraggable(
      dragAnchorStrategy: taskDragAnchorStrategy,
      onDragUpdate: (deltaFiveMinuteIncrements) {
        if (deltaFiveMinuteIncrements != _deltaFiveMinuteIncrements) {
          DateTime newStartTime =
              start.add(Duration(minutes: 5 * deltaFiveMinuteIncrements));
          widget.setAppBarText('${newStartTime.hour}:${newStartTime.minute}');
          setState(() {
            _deltaFiveMinuteIncrements = deltaFiveMinuteIncrements;
          });
        }
      },
      onDragEnd: (deltaFiveMinuteIncrements) {
        DateTime newStartTime =
            start.add(Duration(minutes: 5 * deltaFiveMinuteIncrements));
        widget.setAppBarText(
            'update start time to: ${newStartTime.hour}:${newStartTime.minute}');
        setState(() {
          _deltaFiveMinuteIncrements = deltaFiveMinuteIncrements;
        });
      },
      feedback: UnscheduledContainer(
        title: widget.task.title,
        duration: widget.task.duration,
      ),
      childWhenDragging: Container(),
      child: Container(
          height: 40,
          width: 315,
          decoration: BoxDecoration(
              color: Colors.blue, border: Border.all(color: Colors.black)),
          child: Text(style: textStyle, widget.task.title)),
    );
  }
}

class InboxButton extends StatelessWidget {
  final ScrollController scrollController;
  final ValueSetter<String> setAppBarText;
  final double calendarVerticalOffset;

  const InboxButton(
      {super.key,
      required this.scrollController,
      required this.setAppBarText,
      required this.calendarVerticalOffset});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () {
          Scaffold.of(context).showBottomSheet((BuildContext context) {
            return Inbox(
              scrollController: scrollController,
              calendarVerticalOffset: calendarVerticalOffset,
              setAppBarText: setAppBarText,
            );
          });
        },
        child: Text('Inbox Button'));
  }
}

class Inbox extends StatefulWidget {
  final ScrollController scrollController;
  final ValueSetter<String> setAppBarText;
  final double calendarVerticalOffset;

  Inbox(
      {required this.scrollController,
      required this.setAppBarText,
      required this.calendarVerticalOffset});

  @override
  State<Inbox> createState() => _Inbox();
}

class _Inbox extends State<Inbox> {
  late List<Widget> tasks;

  @override
  Widget build(BuildContext build) {
    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Text('Inbox'),
          Row(
            children: [
              Expanded(
                  child: SizedBox(
                height: 20,
              )),
            ],
          ),
          TaskDraggable(
            task: Task(title: "task 1", duration: 120),
            scrollController: widget.scrollController,
            calendarVerticalOffset: widget.calendarVerticalOffset,
            setAppBarText: widget.setAppBarText,
          )
        ],
      ),
    );
  }
}

class Calendar extends StatelessWidget {
  final double hourHeight;
  final double sidebarWidth;
  final ScrollController controller;

  const Calendar(
      {super.key,
      required this.hourHeight,
      required this.sidebarWidth,
      required this.controller});

  @override
  Widget build(BuildContext context) {
    List<Widget> rows = <Container>[];
    for (int i = 0; i < 24; i++) {
      rows.add(Container(
        height: hourHeight,
        decoration: BoxDecoration(
            border: Border.all(
                color: Colors.grey, strokeAlign: BorderSide.strokeAlignCenter)),
        child: Row(
          children: [
            SizedBox(
              width: sidebarWidth,
              child: Center(child: Text('$i')),
            ),
            VerticalDivider(),
          ],
        ),
      ));
    }

    return ListView(
      controller: controller,
      children: rows,
    );
  }
}

final textStyle = TextStyle(
  decoration: TextDecoration.none,
  color: Colors.black,
  fontSize: 14,
  fontStyle: FontStyle.normal,
  fontFamily: "Roboto",
  fontWeight: FontWeight.normal,
  letterSpacing: 1.5,
  wordSpacing: 1.5,
);
