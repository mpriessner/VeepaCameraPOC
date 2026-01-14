import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../app_p2p_api.dart';
import '../basis_device.dart';

abstract class P2PBasisDevice extends BasisDevice {
  P2PBasisDevice(
      String id, this.username, this.password, String name, String model,
      {String? clientId})
      : _clientId = clientId,
        super(id, name, model) {
    if (clientId != null) {
      _localClientId = true;
    }
    RegExp exp = RegExp(r'^[a-zA-Z]{1,}\d{7,}.*[a-zA-Z]$');
    isVirtualId = exp.hasMatch(id);
    _controller.stream.asyncMap(_createClientPtr).listen((event) {});
    _controller.add(Completer());
  }

  bool _localClientId = false;

  late String username;

  late String password;

  late String cluster;

  late String supplier;

  late bool isVirtualId;

  String? _clientId;

  Future<String> getClientId() async {
    if (_clientId != null) return _clientId!;

    if (isVirtualId) {
      _clientId = await _requestClientId();
    } else {
      _clientId = id;
    }
    return _clientId!;
  }

  set clientId(String value) {
    _clientId = value;
  }

  int? _clientPtr;

  int? get clientPtr => _clientPtr;

  StreamController<Completer<int>> _controller =
      StreamController<Completer<int>>(sync: true);

  Future<int> getClientPtr() async {
    if (_clientPtr != null) return _clientPtr!;
    Completer<int> completer = Completer();
    _controller.add(completer);
    return completer.future;
  }

  Future<bool> changeClientId() async {
    bool result = false;
    if (_localClientId == true && isVirtualId) {
      String? temp = _clientId;
      _clientId = null;
      String clientId = await getClientId();
      if (clientId != null) {
        result = await AppP2PApi().clientChangeId(_clientPtr!, clientId);
        if (result == true) {
          temp = _serviceParam;
          _serviceParam = null;
          _serviceParam = await getServiceParam();
          if (_serviceParam == null) {
            _serviceParam = temp;
          }
        }
      } else {
        _clientId = temp;
      }
    }
    return result;
  }

  Future<int> _createClientPtr(Completer<int> completer) async {
    if (_clientPtr == null) {
      String clientId = await getClientId();
      if (clientId != null) {
        _clientPtr = await AppP2PApi().clientCreate(clientId);
      }
    }
    if (!completer.isCompleted) completer.complete(_clientPtr);
    return _clientPtr!;
  }

  String? _serviceParam;

  Future<String?> getServiceParam() async {
    if (_serviceParam != null) {
      return _serviceParam!;
    }
    _serviceParam = await _requestServiceParam();
    return _serviceParam;
  }

  Map _serviceMap = {
    "ETIM":
        "ECGAEKBKKAJOHFJFEAGDEOEOHJMHHJNAGMEEBHCFBIJALIKMDMANDLPNGGLOIOLNALMJKFDOOIMABKCKJIMM",
    "SURE":
        "BKGPAGBMKFIBDKJHAGGLFJBEHPJECKNIDDFIEBHDFFJKOHKIHDFJCALLHMLAMEKDFGMGLGDCLJMEEFDOJEIPIGENJP",
    "PARC":
        "EBGBEMBMKGJMGAJPEIGIFKEGHBMCHMNFGKEGBFCBBMJELILDCJADCIOLHHLLJBKEAMMBLCDGONMDBJCJJPNFJP",
    "ESCM":
        "AACCEIBLNGIPBOJNFEHDEBAKHHJEGFJBHABNAECLFAJJKLOBHBAFDCIDHKNJIKKFBCMIOPDMLLMGFODDMCNOJGEDNCPMFIGOBEDLEEBLKCODFIHKEOFFKEMLHKNIFDDCEKEKDNNEGK",
    "HVC":
        "BIHOAHEKOMIOCKIHACHLEJAEGPIEDKJHCNBLFEGGFLNDPFPNHBEHGMKLCNKFMNKMBIMCOIDELFMKFDHPJIIPIEAO",
    "ZXBJ":
        "BBGIACBPKEIADLJGAHGKFIBFHOJFCLNCDFFNEDHDFFJKOHKIHDFJCALLHMLAMPKEFCMFLFDBLKMHEGDNJHIMIFEOJM",
    "AIPC":
        "BBGIACBPKEIADLJGAHGKFIBFHOJFCLNCDFFNEDHDFFJKOHKIHDFJCALLHMLAMPKEFCMFLFDBLKMHEGDNJHIMIFEOJM",
    "SIP":
        "BPGBBOEOKJMBHJNCFFDFAEEJCMMHDANKDFADBNHDBGJMLDLOCIACCJOPHMLCJPKJABMELOCMOCJKABHGIANGNPBLIPOIFPCPAIGJDCFDMMLCEFHLACBDPGNA",
    "VSTE":
        "EEGDFHBAKKIOGNJHEGHMFEEDGLNOHJMPHAFPBEDLADILKEKPDLBDDNPOHKKCIFKJBNNNKLCPPPNDBFDL",
    "ZHJ":
        "EFGBFFBKKLJFGJJGECGGFEELHKMIHGNLGBFHBICJBAJILHLPCLABCOOJGPLKJALMAIMJLPDLOIMPAMCAJBNBJL",
    "POLI":
        "AACCEIBLODIGDIJPFGHDEBAKHHJEGFJBHABNAECLFAJJKLOBHBAFDCLGHDPPIIKHBDMJOODNLKMHFPDCMDNPJHECNDPNFJGPBFDKHABDIFOAFLHIEMFHKGMJHINKFBDAEIEIDPNGGI",
    "HSEE":
        "AAHEAGAPLGJCCJIEBFHIEKAHGMIHDJNBDLELEBHDFFJKOHKIHDFJCALLHMLANOLIFGNFKFCBKKNHFGCNIHJMJFFOIM",
    "VSTA":
        "EFGBFFBJKDJKGGJMEAHKFHEJHNNHHANIHIFBBKDFAMJDLKKODNANCBPJGGLEIELOBGNDKADKPGNJBNCNIF",
    "VSTC":
        "EBGBEMBMKGJMGAJPEIGIFKEGHBMCHMNFGKEGBFCBBMJELILDCJADCIOLHHLLJBKEAMMBLCDGONMDBJCJJPNFJP",
    "VSTB":
        "EBGBEMBMKGJMGAJPEIGIFKEGHBMCHMNFGKEGBFCBBMJELILDCJADCIOLHHLLJBKEAMMBLCDGONMDBJCJJPNFJP",
    "SSFX":
        "BGHDBBAGOAINGNINAAHHBOEJGDIGHLIOCMFCFKCDECIKPDPIHEBJGAOBDCPMIBOMAHNPPLCELOMJFDDGIBNHNIBNJGONBHHABFHKGM",
    "VSTD":
        "HZLXLQIDLKASPHIAHUPDEKICEEAUIHLRSWAOSUPEEJSQLOHWEGPAHYPGLQERIBIALKLNEMENHUHXELEHEEEIEKEP-\$\$",
    "VSTG":
        "EEGDFHBOKCIGGFJPECHIFNEBGJNLHOMIHEFJBADPAGJELNKJDKANCBPJGHLAIALAADMDKPDGOENEBECCIK:vstarcam2018",
    "VSTF":
        "HZLXEJIALKHYATPCHULNSVLMEELSHWIHPFIBAOHXIDICSQEHENEKPAARSTELERPDLNEPLKEILPHUHXHZEJEEEHEGEM-\$\$",
    "GYNC":
        "BKHDACBGKNIJDCJPAOGDFBBMHHJMCCNACHFEEDHAFGJJOEKLHAFKCDLIHPLDMHLMFBMPLMDILDMOEPDEJOIFIMEHJF",
    "GCAM":
        "DHGEDPAMLFJBCKIHBGHLEJAEGPIEDKOFCIHBEBHCFEJLOGKJHCFICBLKHNLBOIKJGONHKGCCKJNEFFCOIEJPJGFNIP",
    "OBJ":
        "BPGBBOEOKJMBHJNCFFDFAEEJCMMHDANKDFADBNHDBGJMLDLOCIACCJOPHMLCJPKJABMELOCMOCJKABHGIANGNPBLIPOIFPCPAIGJDCFDMMLCEFHLACBDPGNA",
    "ELSO":
        "AACCEIBLPGJADBJAFJHMEOAFHIJLGKJOHPBCALCEFPJGKEOOHOAKDNKMGKPJIIKHBDMJOODNLKMHFPDCMDNPJHECNDPNFJGPBFDKGFAFIMOPFEHHEDFIKJMGHHNFFODPEHEHDANJGH",
    "ISRP":
        "HZLXEJIALKHYATPCHULNSVLMEELSHWIHPFIBAOHXIDICSQEHENEKPAARSTELERPDLNEPLKEILPHUHXHZEJEEEHEGEM-FKJIJFJGIHHXERFSFPFQFAIGELAQSSPCLMHWEQEHEG",
    "ELSA":
        "HZLXEJIALKHYATPCHULNSVLMEELSHWIHPFIBAOHXIDICSQEHENEKPAARSTELERPDLNEPLKEILPHUHXHZEJEEEHEGEM-FKJIJFJGIHHXERFSFPFQFAIGELAQSSPCLMHWEQEHEG",
    "APLK":
        "EFGBFFBJKBJLGHJIEPGNFPEGHANKHNNBHBFIBNCKAMJMLKKODOAICCPKGFLBIBLCAMMOKCDJOKMCBICCJDMH",
    "EXCE":
        "BJHJAABPPKMBDNMABCDGEMALHMNECFNCDBAFBBGAALMMLPLHDLAMCAOECIKBMMOAAFJOLBDHLMNCEFCGMPIEMMFJJBKDBBHMAFCJHABDIEKE",
    "AHTM":
        "BBGJAHBEKNIJDCJPAOGDFBBMHHJMCCNLDNFBEBHCFEJLOGKJHCFICBLKHNLBMOKEFGMPLODKLBMMENDGJMIHIOEFJH",
    "RUSS":
        "EBGJEGBGKNJFGJJGEKGLFJEFHDMMHCNLGGEHBECEBKIOLOLCCGAMCEOEHOLCJNKIBMMGLFCPPJMJAMDLIJNPIIBHNPPB",
    "WCM":
        "AACDBHBOPJIBDPJFFMCLFGBFHEIAHDMFCIFPEPGCFPMNPNPFGFFEGAKGDIOINIONFNIFLHCPODIKBBGBIJJFNOBLIEOLFKCMEHGLDCFBMGOG",
    "LNFX":
        "AACCBGAEOCILDIJLFBCGFFBGDOIOCMJKCFAFFGGGFKMKPKPFGCEKCAOHGDOPJPPOBJIAOMCFKINLAD",
    "EEEE":
        "HZLXEJIALKHYATPCHULNSVLMEELSHWIHPFIBAOHXIDICSQEHENEKPAARSTELERPDLNEPLKEILPHUHXHZEJEEEHEGEM-FKJIJFJGIHHXERFSFPFQFAIGELAQSSPCLMHWEQEHEG",
    "PPCN":
        "EFGBFFBJKDJIGEJIENGKFIEPHMNGDEJOGAEKBJCLBFIGPLKAGPEFDBKAHOLCNMOMBKNNLBCIPMNHEACDMKJMJEFHNNPD",
    "EMTV":
        "DIGHDDAINHOPBDLEDDFCDHDHFALJEGPCDEGDFABEELMDLEONDKEHHDOECBKMJONEBNKHKAFNIMLMCBEALBLAPIDNKMMDDL",
    "HAXZ":
        "BIGJALAPKJMGGNMGEBDJEKBBHBNJDIMPGNBNABHIAKJOKOPBCKELDCKKGPPKIAKMFJMCKMGOONILAFDEJOIDJMFPMCKMBHGGAICEGNAONI",
    "WGKJ":
        "DHGKCEBPNEJGHHJHBKGNAEFDHJJMGBJEDGGJFJAMEBKEPCPJHFBIGBOADDPNIAONAGNONLDMIKNBGGCMJKMMMDAGINPGAMGLAOGBHH",
    "QSHV":
        "AACCEIBLOCILDIJHFOHLEJACHPJMGNJJHIBFAMCDFIJBKDOJHJANDKLPHGPHIIKHBDMJOODNLKMHFPDCMDNPJHECNDPNFJGPBFDKHBBOIFOIFDHAEEFPKOMBHANCFJDIEAEADHNOGA",
    "GCMN":
        "HZLXEJIALKHYATPCHULNSVLMEELSHWIHPFIBAOHXIDICSQEHENEKPAARSTELERPDLNEPLKEILPHUHXHZEJEEEHEGEM-FKJIJFJGIHHXERFSFPFQFAIGELAQSSPCLMHWEQEHEG",
    "TCXF":
        "EBGDEJBJKGJEGIJOENHHFOEEGMNLHINIHIFDBPDAAOJIKIKDDJAMDKPKGHKJIGLEAGNMKMDFOHNHBBCAJFMB",
    "YUNV":
        "AACCEIBLOKJFCJJBFIHNEPAEHJJKGLJPHOBDAKCFFOJHKFOPHPALDMLBGOOAIIKHBDMJOODNLKMHFPDCMDNPJHECNDPNFJGPBFDKHJAAJEOOFFHGECFJKIMHHGNEFPDOEGEGDBNIGG",
    "QHSV":
        "HZLXEJIALKHYATPCHULNSVLMEELSHWIHPFIBAOHXIDICSQEHENEKPAARSTELERPDLNEPLKEILPHUHXHZEJEEEHEGEM-FKJIJFJGIHHXERFSFPFQFAIGELAQSSPCLMHWEQEHEG",
    "CSCX":
        "BDHAAJAPODJDHDJDBOGJAAFHHNJIGFJADCEJEHCFFFJHPDPKHGBLGCODDAPOIDOOAFNNPMCFKEMCFCCKJPMJMGADIIPDAJGOALGEHC",
    "VIAN":
        "AACCEIBLMFIGBFJFFMHKEIADHOJNGMJIHJBEANCCFJJAKCOIHIAMDLJJHKNLILKEBDMJOODNLKMHFPDCMDNPJHECNDPNFJGPBFDKFGBDKIOKFBHCEGFNKMMDHCNAFLDKECECDFNMGC",
    "PISR":
        "EFGFFBBOKAIEGHJAEDHJFEEOHMNGDCNJCDFKAKHLEBJHKEKMCAFCDLLLHAOCJPPMBHMNOMCJKGJEBGGHJHIOMFBDNPKNFEGCEGCBGCALMFOHBCGMFK",
    "ROSS":
        "HZLXEJIALKHYATPCHULNSVLMEELSHWIHPFIBAOHXIDICSQEHENEKPAARSTELERPDLNEPLKEILPHUHXHZEJEEEHEGEM-FKJIJFJGIHHXERFSFPFQFAIGELAQSSPCLMHWEQEHEG",
    "RTOS":
        "EFGBFFBJKEJKGGJJEEGFFHELHHNNHONHGLFNBHCCAEJDLNLPDDAGCIOFGDLGJMLAAOMOKCDLOONOBICJJIMM",
    "VSTH":
        "EEGDFHBLKGJIGEJLEKGOFMEDHAMHHJNAGGFABMCOBGJOLHLJDFAFCPPHGILKIKLMANNHKEDKOINIBNCPJOMK:vstarcam2018",
    "VSTJ":
        "EEGDFHBLKGJIGEJNEOHEFBEIGANCHHMBHIFEAHDEAMJCKCKJDJAFDDPPHLKJIHLMBENHKDCHPHNJBODA:vstarcam2019",
    "VSTK":
        "EBGDEJBJKGJFGJJBEFHPFCEKHGNMHNNMHMFFBICPAJJNLDLLDHACCNONGLLPJGLKANMJLDDHODMEBOCIJEMA:vstarcam2019",
    "VSTN":
        "EEGDFHBBKBIFGAIAFGHDFLFJGJNIGEMOHFFPAMDMAAIIKBKNCDBDDMOGHLKCJCKFBFMPLMCBPEMG:vstarcam2019",
    "VSTM":
        "EBGEEOBOKHJNHGJGEAGAEPEPHDMGHINBGIECBBCBBJIKLKLCCDBBCFODHLKLJJKPBOMELECKPNMNAICEJCNNJH:vstarcam2019",
    "VSTL":
        "EEGDFHBLKGJIGEJIEIGNFPEEHGNMHPNBGOFIBECEBLJDLMLGDKAPCNPFGOLLJFLJAOMKLBDFOGMAAFCJJPNFJP:vstarcam2019",
    "VSTP":
        "EEGDFHBLKGJIGEJLEIGJFLENHLNBHCNMGAFGBNCOAIJMLKKODNALCCPKGBLHJLLHAHMBKNDFOGNGBDCIJFMB:vstarcam2019",
    "VSGG":
        "EBGDEJBJKGJEGIJHELGKFIEEHBMPHBNNGEFCBGCAAGJBLOLFDJAMCPODGFLEJIKNAFMBKNDHPLNEAM:vstarcam2021",
    "VSKK":
        "EIHGFNBAKMIIGLJHECHIFFECGKNNHONAHAFOBBDOAEJGLLKPDMAMCAPIGGLBIBLCAEMIKEDPOEMMBGCFJHNMJG:veepai2023",
    "VSGM":
        "AGGFBIALNMLLFLLLDKFHCODEBOPLAHLDELCADKFGABMKOFPBDGELDEPEHAPDIDKNFNNKPPDIIFPGDBBNPMPNPOGMLMNNGHEP:vstarcam2021",
    "VSKM":
        "EIHGFNBAKMIIGLJEEAHKFEEJHLNBHCNIGFFDBLCMAKJNLELPDDAGCNOOGILMJFLJAOMKLADEOEMJAPCDJCNPJF:veepai2024",
    "VSLL":
        "EIHGFOBBKKIOGNJKENHHFKEEGMNOHLMNHBFKBBDOAHJBLMKIDLAJCAPIGDLBJGLKAOMILNDJOJMGAHCLJHNMJG:veepai2024",
    "VSME":
        "EBGFEHBHKNJCHDJDEFGDEIEIHINCHCNLGGFABPCLBDJLLELNCNAHCFOCGELMJCLOAKMNLHDDODMPACCOJLNLIKAA:veepai2024",
    "VSIA":
        "EBGDEABAKKJCHHJHEBGEENENHBMDHNNEGIEIBLCLANJKLGLNDBAECGOCGELFJJKJABMELGDCOCMIAKCGJENNJH:veepai2024",
    "VPTK":
        "DAS-8ED76A3380D998ECDA94D6D805A36877AC32B07FFAAD5805AD6F7E3782B7A3FD60DAFC2A75B54DA9A7CBFA8BA808B0B5F4E4EC1668C909DFAF0C0C8FB60C92FE07AE2199BA4A23958A5E5525D1988DB0DFB1A80BE7032B800B0B99775473141C",
    "VPGG":
        "DAS-8ED76A3380D998ECDA94D6D805A36877C0D359112E88293A287AE8138179A4B94F18ED8372AEEC81CCA047696A14299E4819066B372A34EDB9C71A6CA526B12F3B06CB161C66DDB39491417DFF6CBD38",
    "VSGS":
        "EBGDEJBJKGJEGIJHELGKFIEEHBMPHBNNGEFCBGCAAGJBLOLFDJAMCPODGFLEJIKNAFMBKNDHPLNEAM:vstarcam2021",
  };

  Future<String?> _requestServiceParam() async {
    String clientId = await getClientId();
    String head = clientId.substring(0, 4) ?? "";
    if (_serviceMap.containsKey(head)) {
      return _serviceMap[head];
    }
    Response response = await Dio(BaseOptions(
            connectTimeout: const Duration(milliseconds: 5000), sendTimeout: const Duration(milliseconds: 5000), receiveTimeout: const Duration(milliseconds: 5000)))
        .post("https://authentication.eye4.cn/getInitstring",
            data: {
              "uid": [head]
            },
            options: Options(
                headers: {"Content-Type": "application/json; charset=utf-8"}))
        .catchError((error) => Response(requestOptions: RequestOptions(), statusCode: 0));
    if (response.statusCode == 200) {
      return response.data.length > 0 ? response.data[0] : null;
    }
    return null;
  }

  Map getMap(String data) {
    String command = data;
    command = command.replaceAll("\r", "").replaceAll("\n", "");
    List<String> lines = command.split(";");
    Map maps = Map();
    lines.forEach((line) {
      if (line.contains("=")) {
        List<String> keyValue = line.split("=");
        if (keyValue.length >= 2) {
          maps.putIfAbsent(keyValue[0].trim().replaceAll("var ", ""),
              () => keyValue[1].trim().replaceAll('"', ""));
        }
      }
    });
    return maps;
  }

  Future<bool> checkDeviceAp(String id, {int count = 0}) async {
    var bl = false;
    try {
      Response response = await Dio(BaseOptions(
              sendTimeout: const Duration(milliseconds: 5000), connectTimeout: const Duration(milliseconds: 1000), receiveTimeout: const Duration(milliseconds: 5000)))
          .get(
        "http://192.168.168.1:81/get_status.cgi?loginuse=admin&loginpas=888888",
      );

      if (response?.statusCode == 200) {
        Map result = getMap(response.data);
        String realDeviceid = result["realdeviceid"];
        bl = (realDeviceid == id);
      } else
        bl = false;
    } on DioError {
      if (count < 5)
        bl = await checkDeviceAp(id, count: count + 1);
      else
        bl = false;
    }

    print('id:$id ap:$bl count:$count end');
    return bl;
  }

  dynamic _socketError(
      Completer<bool> completer, error, String type, String host, int port) {
    if (!completer.isCompleted) completer.complete(false);

    return null;
  }

  dynamic _socketTcpConnect(Completer<bool> completer, Socket socket) async {
    if (socket == null) {
      if (!completer.isCompleted) completer.complete(false);
      return null;
    }

    socket.write('{"id":"$id","uid":"$_clientId","clientPtr":"$_clientPtr"}');
    var data = await socket.first.timeout(Duration(seconds: 5));
    if (data != null) {
      if (!completer.isCompleted) completer.complete(true);
    } else {
      if (!completer.isCompleted) completer.complete(false);
    }
    socket.close();
    socket.destroy();
    return null;
  }

  Future<String> _requestClientId() async {
    Response response = await Dio(BaseOptions(
            connectTimeout: const Duration(milliseconds: 30000), sendTimeout: const Duration(milliseconds: 30000), receiveTimeout: const Duration(milliseconds: 30000)))
        .get("https://vuid.eye4.cn",
            queryParameters: {"vuid": id},
            options: Options(
                headers: {"Content-Type": "application/json; charset=utf-8"}))
        .catchError((error) {
      String code = _errorResponse(error);
      if (code == '550') {}
      return Response<dynamic>(requestOptions: RequestOptions(), statusCode: 0);
    });
    if (response?.statusCode == 200) {
      supplier = response.data["supplier"];
      cluster = response.data["cluster"];
      _localClientId = false;
      return response.data["uid"];
    }
    return Future.value(null);
  }

  ///转换错误信息.
  ///正常情况下返回服务器响应的错误信息
  ///如果是调用[CancelToken]取消请求,那么[Response]中[statusCode]为0
  ///如果是其他连接错误 [Response]中[statusCode]为 -1
  String _errorResponse(DioError error, {bool checkAuthError = true}) {
    if (error.response != null) {
      if (error.response?.statusCode == 550) {
        var result = error?.response?.data.toString();
        if (result?.contains('vuid inactivated') ?? false) {
          return '550';
        }
      }
      return '-1';
    } else {
      return '-1';
    }
  }

  Future<void> deviceDestroy() async {
    cleanListener();
    int clientPtr = await getClientPtr();

    await AppP2PApi().clientDestroy(clientPtr);

    Directory dir = await getDeviceDirectory();
    dir.deleteSync(recursive: true);
    await _controller.close();
  }
}
