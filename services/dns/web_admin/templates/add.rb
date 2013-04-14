# need to set up:
# r_user_name
# r_host

$add_template = %q{
<!DOCTYPE html>
<html lang="en">
<head>
    <title>Template</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="bootstrap/css/bootstrap.css" rel="stylesheet">
    <link href="css/style.css" rel="stylesheet">
</head>
<body>
<div id="wrap">
    <div class="navbar navbar-fixed-top">
        <div class="navbar-inner">
            <div class="container">
                <a class="brand" href="#">RuCTF 2013</a>
                <div class="nav-collapse collapse">
                    <ul class="nav">
                        <li><a href="#">SES</a></li>
                        <li><a href="#">MapReduse</a></li>
                        <li><a href="#">DB</a></li>
                        <li><a href="#">MessageQueue</a></li>
                        <li class="active"><a href="#">DNS</a></li>
                        <li><a href="#">Balanser</a></li>
                        <li><a href="#">ScriptAPI</a></li>
                    </ul>
                    <div class="pull-right name-pan">
                        <a href="#" class="name"><%= r_user_name %></a>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div id="content">
        <div class="container">
            <div class="header-main">
                RuCTF
            </div>
            <hr>
            <ul class="nav nav-pills">
                <li class="active"><a href="dns-add.html">Add record</a></li>
                <li><a href="dns-all.html">View all records</a></li>
            </ul>
            <div class="tab-content">
                    <form method="POST" action="#" class="add-record">
                        <fieldset>
                            <select  placeholder="Type">
                                <option disabled selected="selected" class="choose">Choose type</option>
                                <option value="">type #1</option>
                                <option value="">type #2</option>
                            </select>
                            <input type="text" name="name" placeholder="Name">
                            <input type="text" name="value" placeholder="Value">
                            <label></label>
                            <button type="submit" class="btn btn-add">Add</button>
                        </fieldset>
                    </form>
            </div>
        </div>
    </div>
</div>
<div id="footer">
    <div class="container">
        <div class="pull-right">
            <a href="http://ructf.org">RuCTF</a>
            <a href="http://hackerdom.ru">HackerDom</a>
            <a href="ructf.org/2013/ru/devteam">Developers</a>
        </div>
    </div>
</div>
</body>
</html>
}