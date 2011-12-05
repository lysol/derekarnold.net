<!--
{
    "title": "Deploying a single page portfolio page with Wordpress and the Bootstrap Framework",
    "post_date": "2011-12-04 09:12 PM",
    "tags": ["php", "wordpress", "portfolio", "bootstrap", "rua"]
}
-->

We recently moved to Des Moines, Iowa and [my wife](http://ruaarnold.com) has
been job hunting. She's had a portfolio online using
[Behance ProSite](http://www.behance.net/prosite), and the predefined
templates are visually good. But if you really need to curate your content, they
don't offer any options for real markup, and you have to really fight the
admin panel to make it look good. 

My wife was really stuck on the idea of a single page site with a static
header for navigation to each section. If you're thinking about doing this,
just use [Bootstrap](http://twitter.github.com/bootstrap/). Their
implementation of a Scroll Spy plugin is the easiest to implement that I've
seen and like most grid frameworks it eliminates all the repeated word of
setting up the page as fluid, non-fluid, multiple columns, etc. It's really a
bit of overkill for a simpler site like this, but still pretty effective.

Also a bit of overkill is Wordpress to managing the content. All it's really
being used is for adding posts with images to query in the template. No posts
are actually being used and the blog isn't even rendered.

The actual portfolio section of the page is a custom JS slider I wrote from
scratch. I opted for multiple sliders using a single viewport. Sections on the
right are automatically created from posts with a given category, using
attached images. Images are automatically resized to fit the slider and pop
out into a lightbox.

The code's pretty sloppy and the server side portions are just in the template
files and functions.php. At any rate, I have it [hosted](http://github.com/lysol/Rua)
at Github and it might serve as a good example of something like this for
someone else.

See my wife's site at [ruaarnold.com](http://ruaarnold.com) and
[follow her on twitter](http://twitter.com/ruaarnold).
