#= require jquery.timeago.js

$ ->
	setTimeout ->
		$('form input').eq(0).focus()
	, 1

	$('#addjob input#triggerKey').keyup (e) ->
		val = $(this).val()
		val = $(this).attr('placeholder') if val.length is 0
		$('#build_url_trigger').text(encodeURIComponent(val))

	$('#addjob input#title').keyup (e) ->
		val = $(this).val()
		val = $(this).attr('placeholder') if val.length is 0
		$('#build_url_title').text(val.replace(/[^a-zA-Z0-9.-]/g, '-'))

	$('.time,.date').timeago()

	$('.deleteLink').click (e) ->
		e.preventDefault()

		$.post $(this).attr('href')

		$(this).parents('tr').slideUp () -> $(this).remove()

		return false
