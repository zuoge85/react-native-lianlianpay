/**
 * Created by lvbingru on 1/5/16.
 */

import {NativeModules, NativeAppEventEmitter} from 'react-native';

const {LianLianAPI} = NativeModules;

const initSdk = LianLianAPI.initSdk;
const pay = LianLianAPI.pay;

export default {
    initSdk,
    pay:function (is_preauth, details, callback) {
        pay(details, function (msg, dic) {
            callback(msg, dic);
        });
    }
}