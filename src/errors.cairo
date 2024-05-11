pub mod Errors {
    pub const ZERO_AMOUNT: felt252 = 'amount cannot be zero';
    pub const ZERO_ADDRESS_CALLER: felt252 = 'Caller cannot be zero addr';
    pub const ZERO_ADDRESS_OWNER: felt252 = 'Owner cannot be zero addr';
    pub const CALLER_NOT_OWNER: felt252 = 'Caller not owner';
    pub const NOT_OWNER: felt252 = 'Not owner';
    pub const NOT_ACTIVE: felt252 = 'kill switch not active';
    pub const INVALID_COUNT_VALUE: felt252 = 'invalid count value';
}
