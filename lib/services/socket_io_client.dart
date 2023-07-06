import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart';

import '../common/controller/language_model_controller.dart';
import '../utils/constants/api_constants.dart';

class SocketIOClient extends GetxService {
  Socket? _socket;
  RxBool isMicConnected = false.obs, hasError = false.obs;
  String? socketError;
  Rx<dynamic> socketResponse = Rx(null);
  late LanguageModelController _languageModelController;

  @override
  void onInit() {
    _languageModelController = Get.find();
    super.onInit();
  }

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
    socketError = null;
    _socket = io(
        _languageModelController.taskSequenceResponse
            .pipelineInferenceSocketAPIEndPoint?.callbackUrl,
        OptionBuilder()
            .setTransports([APIConstants.kWebsocket, APIConstants.kPolling])
            .disableAutoConnect()
            .setAuth({
              _languageModelController
                      .taskSequenceResponse
                      .pipelineInferenceSocketAPIEndPoint
                      ?.inferenceApiKey
                      ?.name:
                  _languageModelController
                      .taskSequenceResponse
                      .pipelineInferenceSocketAPIEndPoint
                      ?.inferenceApiKey
                      ?.value,
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
      socketError = null;
    });

    _socket?.on(APIConstants.kReady, (data) {});

    _socket?.on(APIConstants.kResponse, (data) {
      if (data != null) {
        if (data[0][APIConstants.kDetail] == null) {
          socketResponse.value = data;
        } else {
          socketError = data[0][APIConstants.kDetail][APIConstants.kMessage];
          hasError.value = true;
        }
      }
    });

    _socket?.on(APIConstants.kTerminate, (data) {
      socketError = data;
      isMicConnected.value = false;
      hasError.value = true;
    });

    _socket?.on(APIConstants.kAbort, (data) {
      socketError = data;
      isMicConnected.value = false;
      hasError.value = true;
    });

    _socket?.on(APIConstants.kConnectError, (data) {
      socketError = data.message;
      isMicConnected.value = false;
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
