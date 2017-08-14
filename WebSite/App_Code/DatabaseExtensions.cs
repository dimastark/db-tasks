using System.Linq;
using WebMatrix.Data;

public static class DatabaseExtension
{
    public static string DbPrefix = "[Starkov].dbo";  // Меняешь базу - меняешь префикс

    #region User    
    public static bool IsUserExists(this Database db, string login)
    {
        var query = string.Format("select * from {0}.users where login=@0", DbPrefix);
        return db.Query(query, login).Any();
    }

    public static void CreateUser(this Database db, string[] userFields)
    {
        var query = string.Format(@"insert into {0}.users 
                                    values (@0, @1, @2, @3, @4, @5, @6, @7, {0}.getAddress( @3, @4, @5, @6, @7), @8, @9)",
                                    DbPrefix);
        db.Execute(query, userFields);
    }

    public static void DeleteUser(this Database db, string login)
    {
        var query = string.Format("delete from {0}.users where login = @0", DbPrefix);
       db.Execute(query, login);
    }

    public static dynamic FindUser(this Database db, string login)
    {
        var query = string.Format("select * from {0}.users where login = @0", DbPrefix);
        var res = db.Query(query, login);
        return res == null ? null : res.FirstOrDefault();
    }

    public static dynamic FindUsers(this Database db)
    {
        var query = string.Format("select distinct * from {0}.users order by sirname", DbPrefix);
        return db.Query(query);
    }

    #endregion

    #region Region

    public static dynamic GetRegion(this Database db, string code)
    {
        var query = string.Format(@"select ss, fullname, [index] from {0}.regions order by fullname", DbPrefix);
        return db.Query(query);
    }

    #endregion
}