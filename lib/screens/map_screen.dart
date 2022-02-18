import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:vamhospital/constant/data.dart';
import 'package:vamhospital/model/user.dart';
import 'package:vamhospital/service/firestore_helper.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  bool isLoading = false;
  Set<Marker> markers = <Marker>{};
  Set<Circle> circle = <Circle>{};
  double sliderValue = 200;
  late LocationData locationData;
  LatLng? selectedLocationMarker;
  @override
  void initState() {
    super.initState();
    getData();
  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _goToMyLocation,
        child: const Icon(Icons.my_location),
      ),
      appBar: AppBar(
        title: const Text('Mapview'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: GoogleMap(
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    mapType: MapType.normal,
                    buildingsEnabled: true,
                    compassEnabled: true,
                    indoorViewEnabled: true,
                    mapToolbarEnabled: true,
                    trafficEnabled: true,
                    circles: circle,
                    markers: markers,
                    initialCameraPosition: _kGooglePlex,
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.red[700],
                    inactiveTrackColor: Colors.red[100],
                    trackShape: const RoundedRectSliderTrackShape(),
                    trackHeight: 4.0,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                    thumbColor: Colors.redAccent,
                    overlayColor: Colors.red.withAlpha(32),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 28.0),
                    tickMarkShape: const RoundSliderTickMarkShape(),
                    activeTickMarkColor: Colors.red[700],
                    inactiveTickMarkColor: Colors.red[100],
                    valueIndicatorShape:
                        const PaddleSliderValueIndicatorShape(),
                    valueIndicatorColor: Colors.redAccent,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  child: Slider(
                    value: sliderValue,
                    min: 100,
                    max: 1000,
                    divisions: 10,
                    label: '${sliderValue.round()}',
                    onChanged: (value) {
                      setState(() {
                        sliderValue = value;
                        updateSliderMarker(
                          currentLocation: selectedLocationMarker ??
                              LatLng(
                                locationData.latitude!,
                                locationData.longitude!,
                              ),
                        );
                      });
                    },
                  ),
                )
              ],
            ),
    );
  }

  Future<void> _goToMyLocation() async {
    final GoogleMapController controller = await _controller.future;
    Location location = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationData = await location.getLocation();
    updateMarker(
      currentLocation: LatLng(
        locationData.latitude!,
        locationData.longitude!,
      ),
    );
    markers.add(
      Marker(
        markerId: const MarkerId('myLocation'),
        position: LatLng(
          locationData.latitude!,
          locationData.longitude!,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    setState(() {});
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(locationData.latitude!, locationData.longitude!),
        ),
      ),
    );
  }

  addCircle({LatLng? currentLocation}) {
    circle.clear();
    circle.add(
      Circle(
        circleId: const CircleId('myLocation'),
        center: currentLocation ?? const LatLng(0, 0),
        radius: 10000 * sliderValue / 10,
        fillColor: Colors.blue.withOpacity(0.2),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      ),
    );
  }

  addCustomCircle({
    LatLng? currentLocation,
    LatLng? selectedLocation,
  }) {
    circle.clear();
    markers.clear();
    setState(() {});
    // double distance = Geolocator.distanceBetween(
    //     currentLocation!.latitude,
    //     currentLocation.longitude,
    //     selectedLocation!.latitude,
    //     selectedLocation.longitude);
    sliderValue = 500;
    circle.add(
      Circle(
        circleId: const CircleId('myLocation'),
        center: selectedLocation!,
        radius: 10000 * sliderValue / 10,
        fillColor: Colors.blue.withOpacity(0.2),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      ),
    );

    // if (distance / 1000 < sliderValue) {
    //   sliderValue = distance / 1000;
    // } else {
    //   sliderValue = 1000;
    // }

    markers.add(
      Marker(
        markerId: const MarkerId('myLocation'),
        position: LatLng(
          locationData.latitude!,
          locationData.longitude!,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    for (var item in allUsers) {
      double dis = Geolocator.distanceBetween(
          selectedLocation.latitude,
          selectedLocation.longitude,
          item.location.latitude,
          item.location.longitude);

      if (dis <= 10000 * sliderValue / 10) {
        addMarker(item);
      }
    }

    log(circle.toString());
    setState(() {});
  }

  updateSliderMarker({LatLng? currentLocation}) async {
    markers.clear();

    setState(() {
      isLoading = true;
    });
    markers.add(
      Marker(
        markerId: const MarkerId('myLocation'),
        position: LatLng(
          locationData.latitude!,
          locationData.longitude!,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
    addCircle(currentLocation: currentLocation);

    if (currentLocation != null) {
      for (var item in allUsers) {
        double distance = Geolocator.distanceBetween(
            currentLocation.latitude,
            currentLocation.longitude,
            item.location.latitude,
            item.location.longitude);

        if (distance < 1000 * sliderValue) {
          addMarker(item);
        }
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  updateMarker({LatLng? currentLocation}) async {
    // markers.clear();

    setState(() {
      isLoading = true;
    });
    markers.add(
      Marker(
        markerId: const MarkerId('myLocation'),
        position: LatLng(
          locationData.latitude!,
          locationData.longitude!,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
    // addCircle(currentLocation: currentLocation);

    // if (currentLocation != null) {
    //   for (var item in allUsers) {
    //     double distance = Geolocator.distanceBetween(
    //         currentLocation.latitude,
    //         currentLocation.longitude,
    //         item.location.latitude,
    //         item.location.longitude);

    //     if (distance < 1000 * sliderValue) {
    //       addMarker(item);
    //     }
    //   }
    // }
    setState(() {
      isLoading = false;
    });
  }

  void getData({LatLng? currentLocation}) async {
    markers.clear();
    setState(() {
      isLoading = true;
    });
    await FirestoreService().getAllUserDocs();
    for (var item in allUsers) {
      addMarker(item);
    }
    // await _goToMyLocation();
    setState(() {
      isLoading = false;
    });
  }

  addMarker(User item) {
    markers.add(
      Marker(
        markerId: MarkerId(item.hashCode.toString()),
        position: LatLng(item.location.latitude, item.location.longitude),
        infoWindow: InfoWindow(
          title: item.fullName,
          snippet: item.mobile.toString(),
        ),
        onTap: () {
          selectedLocationMarker = LatLng(
            item.location.latitude,
            item.location.longitude,
          );
          addCustomCircle(
            currentLocation: LatLng(
              locationData.latitude!,
              locationData.longitude!,
            ),
            selectedLocation: LatLng(
              item.location.latitude,
              item.location.longitude,
            ),
          );
          // showDialog(
          //   context: context,
          //   builder: (context) {
          //     return AlertDialog(
          //       title: const Text("Details"),
          //       content: SizedBox(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           mainAxisSize: MainAxisSize.min,
          //           children: <Widget>[
          //             Text("Name: ${item.fullName}"),
          //             Text("Phone number: ${item.mobile.toString()}"),
          //             Text("User type: ${item.userType}"),
          //           ],
          //         ),
          //       ),
          //     );
          //   },
          // );
        },
      ),
    );
  }
}
