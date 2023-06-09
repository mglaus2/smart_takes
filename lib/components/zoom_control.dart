import 'package:flutter/material.dart';

class ZoomControl extends StatefulWidget {
  final double initialValue;
  final ValueChanged<double> onZoomChanged;

  const ZoomControl({
    Key? key,
    required this.initialValue,
    required this.onZoomChanged,
  }) : super(key: key);

  @override
  _ZoomControlState createState() => _ZoomControlState();
}

class _ZoomControlState extends State<ZoomControl> {
  double _zoomValue = 0.0;

  @override
  void initState() {
    super.initState();
    _zoomValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Slider(
            value: _zoomValue,
            min: 0.0,
            max: 100.0,
            onChanged: (newValue) {
              setState(() {
                _zoomValue = newValue;
              });
            },
            onChangeEnd: (newValue) {
              widget.onZoomChanged(newValue);
            },
            activeColor: Colors.white,
            inactiveColor: Colors.grey,
          ),
          Positioned(
            left: (_zoomValue / 100) *
                160, // Adjust the position based on the width of the slider
            top: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (DragUpdateDetails details) {
                final newPosition = details.localPosition.dx.clamp(0.0, 160.0);
                setState(() {
                  _zoomValue = (newPosition / 160) * 100;
                  widget.onZoomChanged(_zoomValue);
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  Icons.zoom_out_map,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
