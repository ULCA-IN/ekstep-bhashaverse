import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart';

class SocketIOClient extends GetxService {
  Socket? _socket;
  RxBool isMicConnected = false.obs, hasError = false.obs;
  RxString socketResponseText = ''.obs;

  void socketEmit(
      {required String emittingStatus,
      required dynamic emittingData,
      required bool isDataToSend}) {
    isDataToSend
        ? _socket?.emit(emittingStatus, emittingData)
        : _socket?.emit(emittingStatus);
  }

  void socketConnect({
    required String apiCallbackURL,
    required String languageCode,
  }) {
    hasError.value = false;
    _socket = io(
        apiCallbackURL,
        OptionBuilder()
            .setTransports(['websocket', 'polling']) // for Flutter or Dart VM
            .disableAutoConnect()
            .setQuery({
              'language': languageCode,
              'EIO': 4,
              'transport': 'websocket',
            })
            .build());

    setSocketMethods();
    _socket?.connect();
  }

  void disconnect() {
    _socket?.close();
    isMicConnected.value = false;
  }

  void setSocketMethods() {
    _socket?.onConnect((receivedData) {});

    _socket?.on('connect-success', (data) {
      isMicConnected.value = true;
      hasError.value = false;
    });

    _socket?.on('response', (data) {
      if (data is List && data.isNotEmpty && data[0].isNotEmpty) {
        socketResponseText.value = data[0];
      }
    });

    _socket?.on('terminate', (data) {
      isMicConnected.value = false;
      hasError.value = true;
    });

    _socket?.on('abort', (data) {
      hasError.value = true;
    });

    _socket?.on('connect_error', (data) {
      hasError.value = true;
    });

    _socket?.onDisconnect((data) {
      isMicConnected.value = false;
    });
  }

  bool isConnected() {
    return _socket != null && _socket!.connected;
  }
}
