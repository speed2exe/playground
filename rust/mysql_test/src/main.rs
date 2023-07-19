use std::borrow::Borrow;

use mysql::prelude::FromRow;
use mysql::prelude::Queryable;
use mysql::FromRowError;
use mysql::Pool;

fn main() {
    let url = "mysql://root@localhost:3306";
    let pool = Pool::new(url).unwrap();
    let conn = pool.get_conn().unwrap();
    let mut conn2 = conn.unwrap();

    {
        let result: Vec<bool> = conn2
            .exec::<bool, &str, ()>("CREATE DATABASE IF NOT EXISTS test3", ())
            .unwrap();
        println!("{:?}", result);
    }
    {
        conn2
            .exec::<bool, &str, ()>(
                "CREATE TABLE IF NOT EXISTS test.users (id int, name varchar(255))",
                (),
            )
            .unwrap();
    }
    {}
    {
        let result = conn2.query::<Person, _>("select id, name from test.user");
        println!("{:?}", result);
    }
    {
        let result = conn2.query_map("select id, name from test.user", |(id, name)| Person {
            id,
            name,
        });
        println!("{:?}", result);
    }
    {}
}

#[derive(Debug, PartialEq, Eq)]
struct Person {
    id: i32,
    name: String,
}

impl FromRow for Person {
    fn from_row_opt(row: mysql::Row) -> Result<Person, FromRowError>
    where
        Person: Sized,
    {
        println!("hello");
        let (id, name) = mysql::from_row(row);
        Ok(Person { id, name })
    }
}
