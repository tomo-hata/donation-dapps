pragma solidity ^0.4.23;
// 2018/7/23現在、修正中。
contract Donation {
/* グローバル変数 */
    address public toDonAddr;   //寄付先アドレス
    address owner; // コントラクトのオーナー(作成者)
    uint public collectAmount;  //集めた寄付金額
    uint public deadline;       //寄付募集期限
    Donar[] public donars;      //寄付者（配列化）
    struct Donar {
        address addr;
        uint amount;
    }
/* プライベート変数 */
    uint8 private flg_sendFix = 0;  //初期値：0, 送金済み：１
    uint8 private flg_sendCancel = 0; //初期値：0, キャンセル済み：１
/* イベント監視を定義 */
    //送金処理
    event sendCoin(address sender,address receiver, uint amount);
    //キャンセル処理
    event cancelDonation(address sender, address receiver, uint amount, uint8 flg);
/* メソッド */
    //初期化メソッド    
    constructor (address _toDonAddr,uint _duration) public {
        toDonAddr = _toDonAddr;
        owner = msg.sender;
        deadline = block.timestamp + _duration * 1 minutes;
    }
    //コントラクト作成者のみに実行実行権限付与
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    //deadlineまでは入金可能
    modifier before_deadline {
        require(block.timestamp < deadline);
        _;
    }
    //deadline以降は出金可能
    modifier after_deadline {
        require(block.timestamp >= deadline);
        _;
    }
    //無名メソッド(etherがコントラクト宛に送金される度に呼び出される)
    function () public payable before_deadline{
        //受取予定者アドレス自身は寄付できない
        require(msg.sender != toDonAddr);
        //終了時間より前なら寄付送金をコントラクト宛に送金可能
        require(block.timestamp < deadline);
        uint amount = msg.value;
        //寄付者と寄付金額を配列として保存
        donars[donars.length++] = Donar({addr: msg.sender, amount:amount});
        collectAmount += amount;
    }
    //送金処理
    function SendCoin() public onlyOwner after_deadline returns(bool _trueorfalse, uint8 _flg_sendFix) {
        //キャンセル済みでなければ処理継続
        require (flg_sendCancel == 0);
        //寄付金額が0以下であれば送金処理を実行しない
        require (collectAmount > 0);
        toDonAddr.transfer(collectAmount);
        flg_sendFix = 1;
        //イベント発行
        emit sendCoin(this,toDonAddr, collectAmount);
        //この辺りに寄付者宛にお礼用のユニークなトークン(ERC721ベースとか)を送付する処理を作成検討中
        //別のトークン用コントラクトを作成し、そのコントラクトを呼び出すやり方も検討中(2018/7/23)
        /* トークン配布用処理を入れる(検討中) */
        return (true, flg_sendFix);
    }
    //寄付キャンセル処理処理（※送金処理実施前まで有効）
    function CancelDonation() public onlyOwner returns(bool _trueorfalse){
        //未送金であれば処理継続
        require (flg_sendFix == 0);
        //寄付者に返金処理
        for (uint i = 0; i < donars.length; ++i){
            donars[i].addr.transfer(donars[i].amount);
        }
        //キャンセルフラグをキャンセル済みにする
        flg_sendCancel = 1;
        //イベント発行
        emit cancelDonation(this,toDonAddr, collectAmount,flg_sendCancel);
        return true;
    }
/* 情報取得系 */
    //コントラクトオーナー取得
    function getOwner() public view returns (address) {
        return owner;
    }
    //寄付金合計額取得
    function getCollectAmount() public view returns (uint) {
        return collectAmount;
    }
    //block.timestamp取得
    function getBlockTimestamp() public view returns(uint) {
        return block.timestamp;
    }
}