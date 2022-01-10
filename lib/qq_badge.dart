import 'dart:math';

import 'package:flutter/material.dart';

class QqBadge extends StatefulWidget {
  const QqBadge({
    Key? key,
    this.radius = 10,
    this.text = '3',
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 8.0,
    ),
    this.onClearBadge,
  }) : super(key: key);

  final double radius;
  final String text;
  final TextStyle textStyle;
  final Function()? onClearBadge;

  @override
  _QqBadgeState createState() => _QqBadgeState();
}

class _QqBadgeState extends State<QqBadge> {
  late Point<double> littleCirclePoint;
  late Point<double> bigCirclePoint;
  late double bigCircleRadius;
  late double littleCircleRadius;
  late double littleCircleRadiusMax;
  late double littleCircleRadiusMin;
  var _overDistance = false;

  @override
  void initState() {
    bigCircleRadius = widget.radius;
    littleCircleRadius = widget.radius;
    littleCircleRadiusMax = widget.radius;
    littleCircleRadiusMin = widget.radius * .5;
    littleCirclePoint = Point(littleCircleRadius, littleCircleRadius);
    bigCirclePoint = Point(bigCircleRadius, bigCircleRadius);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MyPainter(
          bigCirclePoint: bigCirclePoint,
          bigCircleRadius: bigCircleRadius,
          littleCirclePoint: littleCirclePoint,
          littleCircleRadius: littleCircleRadius,
          littleCircleRadiusMax: littleCircleRadiusMax,
          littleCircleRadiusMin: littleCircleRadiusMin,
          textStyle: widget.textStyle,
          text: widget.text,
          onStopDrawBezierPath: (stop) {
            _overDistance = stop;
          }),
      child: Stack(
        children: [
          Positioned(
            top: bigCirclePoint.y - bigCircleRadius,
            left: bigCirclePoint.x - bigCircleRadius,
            // bottom: 80,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPressMoveUpdate: (details) {
                var dy = details.localPosition.dy;
                var dx = details.localPosition.dx;
                bigCirclePoint = Point<double>(dx, dy);
                setState(() {});
              },
              onLongPressEnd: (details) {
                if (_overDistance) widget.onClearBadge?.call();
                bigCirclePoint = Point(bigCircleRadius, bigCircleRadius);
                setState(() {});
              },
              child: SizedBox(
                width: bigCircleRadius * 2,
                height: bigCircleRadius * 2,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _MyPainter extends CustomPainter {
  Point<double> littleCirclePoint;
  Point<double> bigCirclePoint;
  double bigCircleRadius;
  double littleCircleRadius;
  double littleCircleRadiusMax;
  double littleCircleRadiusMin;
  Paint myPaint;
  String text;
  TextStyle textStyle;
  Function(bool stop)? onStopDrawBezierPath;

  _MyPainter({
    required this.littleCirclePoint,
    required this.bigCirclePoint,
    required this.bigCircleRadius,
    required this.littleCircleRadius,
    required this.littleCircleRadiusMax,
    required this.littleCircleRadiusMin,
    required this.text,
    required this.textStyle,
    this.onStopDrawBezierPath,
  }) : myPaint = Paint()
          ..color = Colors.redAccent
          ..isAntiAlias = true
          ..strokeWidth = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    //画大圆
    canvas.drawCircle(
        Offset(bigCirclePoint.x, bigCirclePoint.y), bigCircleRadius, myPaint);

    //得到贝塞尔路径
    Path? bezierPath = _getBezierPath();
    if (bezierPath != null) {
      // 小到必定层度就不见了（不画了）
      canvas.drawCircle(Offset(littleCirclePoint.x, littleCirclePoint.y),
          littleCircleRadius, myPaint);
      // 画贝塞尔曲线
      canvas.drawPath(bezierPath, myPaint);
    }

    // 文字
    TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    var tp = textPainter
      ..text = TextSpan(
        text: text,
        style: textStyle,
      )
      ..layout();

    tp.paint(
        canvas,
        Offset(
            bigCirclePoint.x - tp.width / 2, bigCirclePoint.y - tp.height / 2));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  Path? _getBezierPath() {
    double distance = _getDistance(bigCirclePoint, littleCirclePoint);

    littleCircleRadius = (littleCircleRadiusMax - distance / 10);

    // 超过必定距离 贝塞尔和固定圆都不要画了;
    onStopDrawBezierPath?.call(littleCircleRadius < littleCircleRadiusMin);
    if (littleCircleRadius < littleCircleRadiusMin) {
      return null;
    }

    var bezierPath = Path();

    // 求角 a
    // 求斜率
    double dy = (bigCirclePoint.y - littleCirclePoint.y);
    double dx = (bigCirclePoint.x - littleCirclePoint.x);
    double tanA = dy / dx;
    // 求角a
    double arcTanA = atan(tanA);

    // A
    double aX = (littleCirclePoint.x + littleCircleRadius * sin(arcTanA));
    double aY = (littleCirclePoint.y - littleCircleRadius * cos(arcTanA));

    // B
    double bX = (bigCirclePoint.x + bigCircleRadius * sin(arcTanA));
    double bY = (bigCirclePoint.y - bigCircleRadius * cos(arcTanA));

    // C
    double cX = (bigCirclePoint.x - bigCircleRadius * sin(arcTanA));
    double cY = (bigCirclePoint.y + bigCircleRadius * cos(arcTanA));

    // D
    double dX = (littleCirclePoint.x - littleCircleRadius * sin(arcTanA));
    double dY = (littleCirclePoint.y + littleCircleRadius * cos(arcTanA));

    // 拼装 贝塞尔的曲线路径
    bezierPath.moveTo(aX, aY); // 移动
    // 两个点
    var controlPoint = _getControlPoint();
    // 画了第一条  第一个点（控制点,两个圆心的中心点），终点
    bezierPath.quadraticBezierTo(controlPoint.x, controlPoint.y, bX, bY);

    // 画第二条
    bezierPath.lineTo(cX, cY); // 连接到
    bezierPath.quadraticBezierTo(controlPoint.x, controlPoint.y, dX, dY);

    bezierPath.close();

    return bezierPath;
  }

  /// 得到控制点距离
  Point<double> _getControlPoint() => Point(
      (littleCirclePoint.x + bigCirclePoint.x) / 2,
      (littleCirclePoint.y + bigCirclePoint.y) / 2);

  /// 得到两点之间的距离
  double _getDistance(Point point1, Point point2) =>
      sqrt((point1.x - point2.x) * (point1.x - point2.x) +
          (point1.y - point2.y) * (point1.y - point2.y));
}
