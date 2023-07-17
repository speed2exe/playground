use mysql::Pool;
fn main() {
    let url = "mysql://root@localhost:3306";
    let pool = Pool::new(url).unwrap();
    println!("pool: {:?}", pool);
    let mut conn = pool.get_conn().unwrap();
    println!("conn: {:?}", conn);
}
