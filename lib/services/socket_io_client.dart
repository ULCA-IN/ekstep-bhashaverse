import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart';

import '../models/socket_io_compute_response_model.dart';
import '../utils/constants/api_constants.dart';
import '../utils/environment/streaming_api_key_env.dart';

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

  void socketConnect() {
    hasError.value = false;
    _socket = io(
        APIConstants.ULCA_CONFIG_API_STREAMING_URL,
        OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .setAuth({
              APIConstants.kAuthorizationKeyStreaming: streamingAPIKey,
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
    _socket?.onConnect((data) {
      isMicConnected.value = true;
      hasError.value = false;
    });

    _socket?.on('ready', (data) {});

    _socket?.on('response', (data) {
      if (data != null) {
        SocketIOComputeResponseModel response =
            SocketIOComputeResponseModel.fromJson(data);
        socketResponseText.value = response.results?[0].output?[0].source ?? '';
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
