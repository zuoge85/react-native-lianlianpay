/**
 * Created by lvbingru on 1/5/16.
 */

import {NativeModules, NativeAppEventEmitter} from 'react-native';

const {LianlianPayAPI} = NativeModules;

const initSdk = LianlianPayAPI.initSdk;
const pay = LianlianPayAPI.pay;

export default {
    initSdk,
    pay:function (is_preauth, details, callback) {
        pay(is_preauth, details, function (msg,_1,_2 ,dic) {
            callback(msg, JSON.parse(dic));
        });
    }
}