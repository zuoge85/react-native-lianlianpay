package cn.reactnative.modules.lianlianpay;


import android.os.Handler;
import android.os.Message;
import android.util.Log;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.yintong.pay.utils.BaseHelper;
import com.yintong.pay.utils.Constants;
import com.yintong.pay.utils.Md5Algorithm;
import com.yintong.pay.utils.MobileSecurePayer;
import com.yintong.pay.utils.PayOrder;
import com.yintong.secure.demo.env.EnvConstants;

import org.json.JSONException;
import org.json.JSONObject;

import java.text.SimpleDateFormat;
import java.util.Date;


/**
 * 只实现了卡前置
 */
public class LianlianPayModule extends ReactContextBaseJavaModule {
    private String partner;
    private String partnerKey;
    private Boolean isTest  = false;

    public LianlianPayModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "RCTLianlianPayAPI";
    }


    @ReactMethod
    public void initSdk(String partner, String partnerKey,Boolean isTest) {
        this.partner = partner;
        this.partnerKey = partnerKey;
        this.isTest = isTest;
    }

    @ReactMethod
    public void pay(final Boolean is_preauth, final String details, Callback callback) {
//        PayOrder order = constructPreCardPayOrder(is_preauth, details);
//        String content4Pay = BaseHelper.toJSONString(order);

        String content4Pay = details;

        // 关键 content4Pay 用于提交到支付SDK的订单支付串，如遇到签名错误的情况，请将该信息帖给我们的技术支持
        MobileSecurePayer msp = new MobileSecurePayer();
        if (is_preauth) {
            boolean bRet = msp.payPreAuth(content4Pay, createHandler(callback),
                    Constants.RQF_PAY, getCurrentActivity(), isTest);
            Log.i(LianlianPayModule.class.getSimpleName(), String.valueOf(bRet));
        } else {
            boolean bRet = msp.payAuth(content4Pay, createHandler(callback),
                    Constants.RQF_PAY, getCurrentActivity(), isTest);
            Log.i(LianlianPayModule.class.getSimpleName(), String.valueOf(bRet));
        }
    }


    private Handler createHandler(final Callback callback) {
        return new Handler() {
            public void handleMessage(Message msg) {
                String strRet = (String) msg.obj;
                switch (msg.what) {
                    case Constants.RQF_PAY: {
                        JSONObject objContent = BaseHelper.string2JSON(strRet);
                        String retCode = objContent.optString("ret_code");
                        String retMsg = objContent.optString("ret_msg");

                        // 成功
                        if (Constants.RET_CODE_SUCCESS.equals(retCode)) {
                            // TODO 卡前置模式返回的银行卡绑定协议号，用来下次支付时使用，此处仅作为示例使用。正式接入时去掉
                            String agreementno = objContent.optString("agreementno", "");
                            Log.i(LianlianPayModule.class.getSimpleName(), "支付成功，交易状态码：" + retCode + " 返回报文:" + strRet);
                            callback.invoke("成功", agreementno, retCode, strRet);
                        } else if (Constants.RET_CODE_PROCESS.equals(retCode)) {
                            // TODO 处理中，掉单的情形
                            String resulPay = objContent.optString("result_pay");
                            if (Constants.RESULT_PAY_PROCESSING.equalsIgnoreCase(resulPay)) {
                                Log.i(LianlianPayModule.class.getSimpleName(),
                                        objContent.optString("ret_msg") + "交易状态码：" + retCode + " 返回报文:" + strRet);
                                callback.invoke("失败", null, retCode, strRet);
                            }
                        } else {
                            // TODO 失败
                            Log.i(LianlianPayModule.class.getSimpleName(), retMsg + "，交易状态码:" + retCode + " 返回报文:" + strRet);
                            callback.invoke("失败", null, retCode, strRet);
                        }
                    }
                    break;
                }
                super.handleMessage(msg);
            }
        };

    }

    private PayOrder constructPreCardPayOrder(final Boolean is_preauth, final ReadableMap details) {
        SimpleDateFormat dataFormat = new SimpleDateFormat("yyyyMMddHHmmss");
        Date date = new Date();
        String timeString = dataFormat.format(date);

        PayOrder order = new PayOrder();
        order.setBusi_partner(details.getString("busi_partner"));
        order.setNo_order(details.getString("no_order"));
        order.setDt_order(timeString);
        order.setName_goods(details.getString("name_goods"));
        order.setNotify_url(details.getString("notify_url"));
        order.setSign_type(PayOrder.SIGN_TYPE_MD5);
        order.setValid_order(details.getString("valid_order"));

        order.setUser_id(details.getString("user_id"));
        order.setId_no(details.getString("id_no"));

        order.setAcct_name(details.getString("acct_name"));
        order.setMoney_order(details.getString("money_order"));

        // 银行卡卡号，该卡首次支付时必填
        order.setCard_no(details.getString("card_no"));
        // 银行卡历次支付时填写，可以查询得到，协议号匹配会进入SDK，
        //order.setNo_agree(details.getString("no_agree"));


        //    private String flag_modify; // 修改前置姓名、身份证号的标识 1为不可修改 0为可修改
        order.setFlag_modify(details.getString("flag_modify"));
        // 风险控制参数
        order.setRisk_item(constructRiskItem(details));

        String sign = "";
        // TODO 商户号
        if (is_preauth) {
            order.setOid_partner(this.partner);
        } else {
            order.setOid_partner(this.partner);
        }
        String content = BaseHelper.sortParam(order);
        // TODO MD5 签名方式, 签名方式包括两种，一种是MD5，一种是RSA 这个在商户站管理里有对验签方式和签名Key的配置。
        if (is_preauth) {
            sign = Md5Algorithm.getInstance().sign(content, this.partnerKey);
        } else {
            sign = Md5Algorithm.getInstance().sign(content, this.partnerKey);
        }
        order.setSign(sign);
        return order;
    }

    private String constructRiskItem(final ReadableMap details) {
        JSONObject mRiskItem = new JSONObject();
        try {
            mRiskItem.put("user_info_bind_phone", details.getString("user_info_bind_phone"));
            mRiskItem.put("user_info_dt_register", details.getString("user_info_dt_register"));
            mRiskItem.put("frms_ware_category", details.getString("frms_ware_category"));
            mRiskItem.put("request_imei", details.getString("request_imei"));

        } catch (JSONException e) {
            e.printStackTrace();
        }

        return mRiskItem.toString();
    }
}
