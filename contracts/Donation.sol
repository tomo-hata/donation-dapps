pragma solidity ^0.4.23;
// 2018/7/23���݁A�C�����B
contract Donation {
/* �O���[�o���ϐ� */
    address public toDonAddr;   //��t��A�h���X
    address owner; // �R���g���N�g�̃I�[�i�[(�쐬��)
    uint public collectAmount;  //�W�߂���t���z
    uint public deadline;       //��t��W����
    Donar[] public donars;      //��t�ҁi�z�񉻁j
    struct Donar {
        address addr;
        uint amount;
    }
/* �v���C�x�[�g�ϐ� */
    uint8 private flg_sendFix = 0;  //�����l�F0, �����ς݁F�P
    uint8 private flg_sendCancel = 0; //�����l�F0, �L�����Z���ς݁F�P
/* �C�x���g�Ď����` */
    //��������
    event sendCoin(address sender,address receiver, uint amount);
    //�L�����Z������
    event cancelDonation(address sender, address receiver, uint amount, uint8 flg);
/* ���\�b�h */
    //���������\�b�h    
    constructor (address _toDonAddr,uint _duration) public {
        toDonAddr = _toDonAddr;
        owner = msg.sender;
        deadline = block.timestamp + _duration * 1 minutes;
    }
    //�R���g���N�g�쐬�҂݂̂Ɏ��s���s�����t�^
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    //deadline�܂ł͓����\
    modifier before_deadline {
        require(block.timestamp < deadline);
        _;
    }
    //deadline�ȍ~�͏o���\
    modifier after_deadline {
        require(block.timestamp >= deadline);
        _;
    }
    //�������\�b�h(ether���R���g���N�g���ɑ��������x�ɌĂяo�����)
    function () public payable before_deadline{
        //���\��҃A�h���X���g�͊�t�ł��Ȃ�
        require(msg.sender != toDonAddr);
        //�I�����Ԃ��O�Ȃ��t�������R���g���N�g���ɑ����\
        require(block.timestamp < deadline);
        uint amount = msg.value;
        //��t�҂Ɗ�t���z��z��Ƃ��ĕۑ�
        donars[donars.length++] = Donar({addr: msg.sender, amount:amount});
        collectAmount += amount;
    }
    //��������
    function SendCoin() public onlyOwner after_deadline returns(bool _trueorfalse, uint8 _flg_sendFix) {
        //�L�����Z���ς݂łȂ���Ώ����p��
        require (flg_sendCancel == 0);
        //��t���z��0�ȉ��ł���Α������������s���Ȃ�
        require (collectAmount > 0);
        toDonAddr.transfer(collectAmount);
        flg_sendFix = 1;
        //�C�x���g���s
        emit sendCoin(this,toDonAddr, collectAmount);
        //���̕ӂ�Ɋ�t�҈��ɂ���p�̃��j�[�N�ȃg�[�N��(ERC721�x�[�X�Ƃ�)�𑗕t���鏈�����쐬������
        //�ʂ̃g�[�N���p�R���g���N�g���쐬���A���̃R���g���N�g���Ăяo��������������(2018/7/23)
        /* �g�[�N���z�z�p����������(������) */
        return (true, flg_sendFix);
    }
    //��t�L�����Z�����������i�������������{�O�܂ŗL���j
    function CancelDonation() public onlyOwner returns(bool _trueorfalse){
        //�������ł���Ώ����p��
        require (flg_sendFix == 0);
        //��t�҂ɕԋ�����
        for (uint i = 0; i < donars.length; ++i){
            donars[i].addr.transfer(donars[i].amount);
        }
        //�L�����Z���t���O���L�����Z���ς݂ɂ���
        flg_sendCancel = 1;
        //�C�x���g���s
        emit cancelDonation(this,toDonAddr, collectAmount,flg_sendCancel);
        return true;
    }
/* ���擾�n */
    //�R���g���N�g�I�[�i�[�擾
    function getOwner() public view returns (address) {
        return owner;
    }
    //��t�����v�z�擾
    function getCollectAmount() public view returns (uint) {
        return collectAmount;
    }
    //block.timestamp�擾
    function getBlockTimestamp() public view returns(uint) {
        return block.timestamp;
    }
}