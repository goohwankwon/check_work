import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum LocationStatus{
  enabled,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class HomeScreen extends StatelessWidget {
  static final LatLng latLng = const LatLng(37.5233273, 126.921252);
  static final Marker marker = Marker(
    markerId: MarkerId('company'),
    position: latLng,
  );
  static final Circle circle = Circle(
    circleId: CircleId('checkWorkCircle'),
    center: latLng,
    radius: 100,
    strokeColor: Colors.blue,
    strokeWidth: 1,
    fillColor: Colors.blue.withOpacity(0.5),
  );
  final double checkRadius = 100.0;

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Check in for work')),
      body: FutureBuilder(
        future: checkPermission(),
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.connectionState == ConnectionState.waiting) {
            return renderLoading();
          }

          if (snapshot.data == LocationStatus.serviceDisabled) {
            return renderBody(context);
          }

          return Center(child: Text("위치 권한이 필요합니다."));
        },
      ),
    );
  }

  Widget renderBody(BuildContext context) {
    final currContext = context;
    return SafeArea(
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: latLng, zoom: 16.0),
            markers: Set.from({marker}),
            circles: Set.from({circle}),
            myLocationEnabled: true,
          ),
          Positioned(
            bottom: 13,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final curPosition = await Geolocator.getCurrentPosition();
                  final distance = Geolocator.distanceBetween(
                    curPosition.latitude,
                    curPosition.longitude,
                    latLng.latitude,
                    latLng.longitude,
                  );

                  bool canCheck = distance < checkRadius;

                  final result = await showDialog<bool>(
                    context: currContext,
                    barrierColor: Colors.black.withOpacity(0.5),
                    barrierDismissible: false,
                    builder:
                        (_) => AlertDialog(
                          title: Text('출근하기'),
                          content: Text(
                            canCheck ? '출근 등록하시겠습니까?' : '출근할 수 없는 위치입니다.',
                          ),
                          actions: [
                            if (canCheck)
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                                child: Text('확인'),
                              ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              child: Text('취소'),
                            ),
                          ],
                        ),
                  );

                  if (result ?? false) {
                    print('출근 완료');
                  } else {
                    print('출근 실패');
                  }
                },
                style: ElevatedButton.styleFrom(
                  fixedSize: Size(200, 45),
                  backgroundColor: Colors.blue[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'CHECK',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget renderLoading() {
    return Center(child: CircularProgressIndicator());
  }

  Future<LocationStatus> checkPermission() async {
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();

    //위치 서비스 활성화
    if (!isLocationEnabled) {
      return LocationStatus.enabled;
    }

    LocationPermission checkedPermission = await Geolocator.checkPermission();
    if (checkedPermission == LocationPermission.denied) {
      checkedPermission = await Geolocator.requestPermission();
      if (checkedPermission == LocationPermission.denied) {
        return LocationStatus.permissionDenied;
      }
    }

    if (checkedPermission == LocationPermission.deniedForever) {
      return LocationStatus.permissionDeniedForever;
    }

    return LocationStatus.serviceDisabled;
  }
}
