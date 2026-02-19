// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import "./Events.sol";

contract ExcelSchool {
    //handle staff
    address admin;

    mapping(uint8 => uint256) public levelPrice;

    constructor() {
        admin = msg.sender;
        levelPrice[1] = 0.014 ether;
        levelPrice[2] = 0.025 ether;
        levelPrice[3] = 0.05 ether;
        levelPrice[4] = 0.09 ether;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can make this call");
        _;
    }

    enum Roles {
        admin,
        staff,
        student
    }

    enum Status {
        unpaid,
        paid
    }

    struct Staff {
        uint id;
        string name;
        address wallet;
        uint salary;
        bool paid;
        uint paidAt;
        Roles role;
        bool claimed;
        uint claimedAt;
    }

    struct Student {
        uint id;
        string name;
        address wallet;
        uint8 level;
        uint8 age;
        uint amoutPaid;
        Status status;
        Roles role;
        bool claimed;
        uint claimedAt;
    }

    //student modifier
    modifier onlyStudent(Roles _role) {
        require(_role == Roles.student, "Only student");
        _;
    }
    // staff modifiers
    modifier onlyStaff(Roles _role) {
        require(_role == Roles.staff, "Only staff");
        _;
    }

    


    //mappings
    mapping(address => Student) public studentDetails;
    mapping(address => uint256) lastPaid;
    uint256 constant PAY_INTERVAL = 30 days;
    mapping(address => Staff) public staffDetails;
    mapping(address => uint256) public schoolAccount;


    //check if paid recently modifier
    modifier checkIfStaffIsPaidRecently( address _staff_wallet) {
        require(staffDetails[_staff_wallet].role == Roles.staff,"Only staff are paid");
         uint _now = block.timestamp;
         uint last = lastPaid[_staff_wallet];
         require(_now < last + PAY_INTERVAL,"Paid recently");
        _;
    }

    Staff[] public staff;
    Student[] public students;
    mapping(address => Roles) userRoles;

    function addStudent(string memory _name,uint8 _level,uint8 _age) public onlyAdmin {
        require(_level > 0 && _level <= 4, "Level Exceeded");
        uint index = students.length;
        Student memory newStudent = Student({
            id: index,
            name: _name,
            wallet: address(0),
            level: _level,
            age: _age,
            amoutPaid: 0,
            status: Status.unpaid,
            role: Roles.student,
            claimed: false,
            claimedAt:0
        });
        students.push(newStudent);
        emit Events.StudentEvent("student added sucessfully", newStudent.id);
    }

    function addStaff( string memory _name, uint _salary) public onlyAdmin {
        uint _id = staff.length;
        Staff memory newStaff = Staff({
            id: _id,
            name: _name,
            wallet: address(0),
            salary: _salary,
            paid: false,
            paidAt: 0,
            role: Roles.staff,
            claimed: false,
            claimedAt:0
        });
        staff.push(newStaff);
        emit Events.StaffEvent(newStaff.id,newStaff.wallet);
    }

    function claimStaffId(uint _Id) external  onlyStaff(Roles.staff) {
        require(_Id < staff.length, "Staff not found");

        Staff storage unClaimedStaff = staff[_Id];

        require(!unClaimedStaff.claimed, "Already claimed");

        unClaimedStaff.wallet = msg.sender;
        unClaimedStaff.claimed = true;
        unClaimedStaff.claimedAt = block.timestamp;


        emit Events.StaffEvent(_Id, unClaimedStaff.wallet);
    }



    function claimStudentId( uint _Id) external payable onlyStudent(Roles.student) {
        require(_Id < students.length, "Student not found");

        Student storage student = students[_Id];

        require(!student.claimed, "Already claimed");

        uint fee = levelPrice[student.level];
        require(fee > 0, "Invalid level");
        require(msg.value == fee, "Wrong amount");

       schoolAccount[msg.sender] = schoolAccount[msg.sender] + msg.value;
        student.wallet = msg.sender;

        student.amoutPaid = msg.value;

        student.claimed = true;
        student.claimedAt = block.timestamp;

        emit Events.StudentClaimEvent(_Id, msg.value, student.wallet);
    }

    function payStaff (uint _staffId,address _wallet) external payable onlyAdmin checkIfStaffIsPaidRecently(_wallet) {
      
    }

    receive() external payable {}

    fallback() external payable {}
}
