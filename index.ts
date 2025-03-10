import { NativeModules } from "react-native";

const load = (fileUrl: string): Promise<any> => {
  var data = NativeModules.nativeFunction;
  return data.load(fileUrl);
};
export default load;
